# One entry of the audit log: an admin or moderator action in a feedback space (moderation,
# site settings, OAuth, webhooks, invitations, API keys). Shown in Site settings › Audit log.
# Entries older than AUDIT_LOG_RETENTION_DAYS (default 365) are removed when new ones arrive.
class AuditEvent < ApplicationRecord
  include TenantOwnable

  belongs_to :user, optional: true

  SOURCES = %w[app api mcp].freeze
  # Never stored, only marked as changed
  SECRET_FIELD = /secret|password|digest|encrypted|headers|(\A|_)token\z|\Aurl\z/
  MAX_VALUE = 500

  # Category of an action ("webhook.update" → "webhook") for the filter in the UI
  CATEGORIES = %w[post comment user board post_status site_settings o_auth saml ldap webhook invitation api_key].freeze

  validates :action, presence: true
  validates :source, inclusion: { in: SOURCES }

  scope :in_category, ->(category) { where('action LIKE ?', "#{sanitize_sql_like(category)}.%") }

  def self.retention_days
    ENV.fetch('AUDIT_LOG_RETENTION_DAYS', '365').to_i
  end

  # changes: { "field" => [old, new] } or ActiveRecord saved_changes; prefix names the model
  def self.record!(action:, actor:, subject: nil, changes: {}, prefix: nil, source: 'app', ip: nil, subject_label: nil)
    entry = create!(
      action: action,
      user: actor,
      actor_label: actor&.full_name,
      subject_type: subject&.class&.name,
      subject_id: subject&.id,
      subject_label: (subject_label || label_for(subject)).to_s.truncate(200).presence,
      field_changes: clean(changes, prefix.nil? ? subject&.class&.model_name&.singular : prefix),
      source: source,
      ip: ip
    )
    where(created_at: ...retention_days.days.ago).delete_all if retention_days.positive?
    entry
  end

  def self.label_for(subject)
    case subject
    when nil then nil
    when Post then subject.title
    when User then subject.full_name
    when Comment then subject.body.to_s.squish
    when TenantSetting, Tenant then subject.respond_to?(:site_name) ? subject.site_name : nil
    else subject.try(:name)
    end
  end

  def self.clean(changes, prefix)
    (changes || {}).to_h.except('updated_at', 'created_at', 'id', 'tenant_id').each_with_object({}) do |(field, (from, to)), out|
      key = [prefix, field].reject(&:blank?).join('.')
      out[key] = field.to_s.match?(SECRET_FIELD) ? ['[filtered]', '[filtered]'] : [shorten(from), shorten(to)]
    end
  end

  def self.shorten(value)
    value.is_a?(String) ? value.truncate(MAX_VALUE) : value.as_json
  end
end
