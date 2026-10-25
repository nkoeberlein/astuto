class Invitation < ApplicationRecord
  include TenantOwnable

  belongs_to :tenant

  # The invitation for this email if the token matches and it is neither
  # expired nor already accepted; otherwise nil
  def self.find_acceptable(email:, token:)
    return nil if token.blank?

    invitation = find_by(email: email)
    return nil if invitation.nil? || invitation.expired? || invitation.accepted_at.present?
    return nil unless ActiveSupport::SecurityUtils.secure_compare(
      invitation.token_digest.to_s, Digest::SHA256.hexdigest(token.to_s)
    )

    invitation
  end

  def expired?
    updated_at <= 3.months.ago
  end
end
