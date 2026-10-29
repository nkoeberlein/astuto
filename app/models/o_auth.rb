class OAuth < ApplicationRecord
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  include TenantOwnable
  extend FriendlyId

  has_many :tenant_default_o_auths, dependent: :destroy

  attr_accessor :state

  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :is_enabled, inclusion: { in: [true, false] }
  validates :client_id, presence: true
  validates :client_secret, presence: true
  validates :authorize_url, presence: true
  validates :token_url, presence: true
  validates :profile_url, presence: true
  validates :scope, presence: true
  validates :json_user_email_path, presence: true
  validate :profile_headers_format

  # [{ "key" => ..., "value" => ... }]; rows without a key are dropped
  def profile_headers=(value)
    rows = Array(value).filter_map do |header|
      header = header.to_unsafe_h if header.respond_to?(:to_unsafe_h)
      next unless header.is_a?(Hash)

      key = header['key'] || header[:key]
      { 'key' => key.to_s.strip, 'value' => (header['value'] || header[:value]).to_s } if key.present?
    end
    super(rows)
  end

  friendly_id :generate_random_slug, use: :scoped, scope: :tenant_id

  def profile_headers_format
    # Header names: visible ASCII without separators (RFC 9110 token)
    return if Array(profile_headers).all? { |header| header['key'].to_s.match?(/\A[!#$%&'*+\-.^_`|~0-9A-Za-z]+\z/) }

    errors.add(:profile_headers, :invalid)
  end

  def is_default?
    tenant_id == nil
  end

  def callback_url
    # Default OAuths are available to all tenants
    # but must have a single callback url:
    # for this reason, we don't preprend tenant subdomain
    # but rather use the "login" subdomain
    if self.is_default?
      get_url_for(method(:o_auth_callback_url), resource: self, disallow_custom_domain: true, options: { subdomain: "login", host: Rails.application.base_url })
    else
      get_url_for(method(:o_auth_callback_url), resource: self, disallow_custom_domain: true)
    end
  end

  def authorize_url_with_query_params
    "#{authorize_url}?"\
    "response_type=code&"\
    "client_id=#{client_id}&"\
    "redirect_uri=#{callback_url()}&"\
    "scope=#{scope}&"\
    "state=#{state}"
  end

  def default_o_auth_is_enabled
    is_default? and tenant_default_o_auths.exists?
  end

  def generate_random_slug
    loop do
      self.slug = SecureRandom.hex(8)
      break unless self.class.exists?(slug: slug)
    end
    slug
  end

  class << self
    # returns all tenant-specific o_auths plus all default o_auths that are enabled site-wide
    def include_all_defaults
      unscoped.where(tenant_id: nil, is_enabled: true).or(where(tenant_id: Current.tenant))
    end

    # returns all tenant-specific o_auths plus all default o_auths that are enabled both site-wide and for the current tenant
    def include_defaults
      unscoped.left_outer_joins(:tenant_default_o_auths).where(tenant_default_o_auths: { tenant_id: Current.tenant }, is_enabled: true).or(where(tenant_id: Current.tenant))
    end

    # returns all default o_auths that are enabled site-wide
    def include_only_defaults
      unscoped.where(tenant_id: nil, is_enabled: true)
    end
  end
end
