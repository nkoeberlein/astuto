# Daily clean-up of personal data that is no longer needed (GDPR storage limitation,
# docs/privacy.md). Every period is configurable; 0 switches that part off.
#   UNCONFIRMED_ACCOUNT_RETENTION_DAYS (30)  sign-ups never confirmed, without posts, comments or votes
#   IP_RETENTION_DAYS (90)                    sign-in IPs of users and IPs in the audit log
#   INVITATION_RETENTION_DAYS (180)           invitations nobody accepted
# The audit log itself is trimmed when entries are written (AUDIT_LOG_RETENTION_DAYS).
class PurgeExpiredData < ActiveJob::Base
  queue_as :default

  def perform
    result = Hash.new(0)

    Tenant.find_each do |tenant|
      Current.set(tenant: tenant) do
        result[:unconfirmed_accounts] += purge_unconfirmed_accounts
        result[:sign_in_ips] += purge_sign_in_ips
        result[:audit_ips] += purge_audit_ips
        result[:invitations] += purge_invitations
      end
    end

    logger.info { "[privacy] Purged expired data: #{result.to_h}" }
    result.to_h
  end

  private

    def days(name, default)
      ENV.fetch(name, default.to_s).to_i
    end

    def purge_unconfirmed_accounts
      retention = days('UNCONFIRMED_ACCOUNT_RETENTION_DAYS', 30)
      return 0 unless retention.positive?

      stale = User.where(confirmed_at: nil, created_at: ...retention.days.ago)
        .where.missing(:posts, :comments, :likes)
        .where.not(role: 'owner')
      stale.find_each.count { |user| user.destroy }
    end

    def purge_sign_in_ips
      retention = days('IP_RETENTION_DAYS', 90)
      return 0 unless retention.positive?

      User.where(last_sign_in_at: ...retention.days.ago)
        .where('current_sign_in_ip IS NOT NULL OR last_sign_in_ip IS NOT NULL')
        .update_all(current_sign_in_ip: nil, last_sign_in_ip: nil)
    end

    def purge_audit_ips
      retention = days('IP_RETENTION_DAYS', 90)
      return 0 unless retention.positive?

      AuditEvent.where(created_at: ...retention.days.ago).where.not(ip: nil).update_all(ip: nil)
    end

    def purge_invitations
      retention = days('INVITATION_RETENTION_DAYS', 180)
      return 0 unless retention.positive?

      Invitation.where(accepted_at: nil, updated_at: ...retention.days.ago).delete_all
    end
end
