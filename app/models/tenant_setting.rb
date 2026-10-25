class TenantSetting < ApplicationRecord
  include TenantOwnable

  POST_SORT_OPTIONS = %w[trending newest most_voted oldest].freeze

  belongs_to :tenant

  validates :custom_css, length: { maximum: 32000 }
  validates :default_post_sorting, inclusion: { in: POST_SORT_OPTIONS }
  validates :mail_logo_size, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1024 }
  validate :custom_links_format
  validate :logo_custom_url_format

  enum :brand_display, [
    :name_and_logo,
    :name_only,
    :logo_only,
    :no_name_no_logo
  ]

  enum :logo_links_to, [
    :root_page,
    :custom_url,
    :nothing
  ]

  enum :collapse_boards_in_header, [
    :no_collapse,
    :always_collapse
  ]

  enum :email_registration_policy, [
    :all_allowed,
    :none_allowed,
    :custom_domains_allowed
  ]

  enum :feedback_approval_policy, [
    :anonymous_require_approval,
    :never_require_approval,
    :always_require_approval,
  ]

  # custom_links is stored as [{ "label" => ..., "url" => ... }]; tolerate
  # missing entries from the free-text settings form and reject malformed ones.
  def custom_links=(value)
    links = Array(value).filter_map do |link|
      next unless link.is_a?(Hash) || link.is_a?(ActionController::Parameters)

      label = (link[:label] || link["label"]).to_s.strip
      url = (link[:url] || link["url"]).to_s.strip
      next if label.blank? || url.blank?

      { "label" => label, "url" => url }
    end
    super(links.uniq)
  end

  # Approval status for a new post, following feedback_approval_policy.
  # Moderators' posts are always approved.
  def approval_status_for_new_post(user:, anonymous:)
    return 'approved' if user&.moderator?

    case feedback_approval_policy
    when 'never_require_approval' then 'approved'
    when 'anonymous_require_approval' then anonymous ? 'pending' : 'approved'
    else 'pending'
    end
  end

  # Links that are safe to render; filters out unsafe URLs saved before validation existed
  def safe_custom_links
    custom_links.select { |link| SafeUrl.safe?(link["url"]) }
  end

  def safe_logo_custom_url
    SafeUrl.sanitize(logo_custom_url)
  end

  private

    def custom_links_format
      return if custom_links.all? do |link|
        link.fetch("label").is_a?(String) && SafeUrl.safe?(link.fetch("url"))
      end

      errors.add(:custom_links, :invalid)
    end

    def logo_custom_url_format
      return if logo_custom_url.blank? || SafeUrl.safe?(logo_custom_url)

      errors.add(:logo_custom_url, :invalid)
    end
end
