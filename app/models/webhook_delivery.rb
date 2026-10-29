# One run of a webhook: HTTP status, duration, error (template, JSON or network) and the start
# of the response, shown in Site settings › Webhooks (#458). Only the newest KEEP per webhook stay.
class WebhookDelivery < ApplicationRecord
  include TenantOwnable

  KEEP = 50
  MAX_TEXT = 2000

  belongs_to :webhook

  after_create :prune

  def self.record!(webhook:, trigger:, is_test:, success:, duration_ms:, http_status: nil, error: nil, response_body: nil)
    create!(
      webhook: webhook, trigger: trigger.to_s, is_test: is_test, success: success, duration_ms: duration_ms,
      http_status: http_status, error: error&.truncate(MAX_TEXT), response_body: response_body.to_s.truncate(MAX_TEXT).presence
    )
  end

  private

    def prune
      stale = self.class.where(webhook_id: webhook_id).order(created_at: :desc, id: :desc).offset(KEEP).pluck(:id)
      self.class.where(id: stale).delete_all if stale.any?
    end
end
