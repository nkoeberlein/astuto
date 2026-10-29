# Sends invitation emails (Site settings › Invitations, app API).
# The body must contain %link%, which becomes the personal sign-up link.
# Skips addresses that are invalid, already registered or already accepted.
class SendInvitationsWorkflow
  MAX_RECIPIENTS = 20
  LINK_PLACEHOLDER = '%link%'.freeze

  Result = Struct.new(:sent, :skipped, :error, keyword_init: true)

  # link_for: callable(token, email) -> sign-up URL
  def initialize(to:, subject:, body:, link_for:)
    @emails = (to.is_a?(Array) ? to : to.to_s.split(',')).map { |email| email.to_s.strip }.reject(&:blank?).uniq
    @subject = subject.to_s
    @body = body.to_s
    @link_for = link_for
  end

  def run
    return Result.new(sent: 0, skipped: [], error: :too_many) if @emails.size > MAX_RECIPIENTS
    return Result.new(sent: 0, skipped: [], error: :link_missing) unless @body.include?(LINK_PLACEHOLDER)

    sent = 0
    skipped = []
    @emails.each do |email|
      if send_to(email)
        sent += 1
      else
        skipped << email
      end
    end
    Result.new(sent: sent, skipped: skipped, error: nil)
  end

  # Sends a test email to `email` without saving an invitation
  def test(email)
    return :link_missing unless @body.include?(LINK_PLACEHOLDER)

    token = SecureRandom.hex(16)
    invitation = Invitation.new(email: email, token_digest: Digest::SHA256.hexdigest(token))
    InvitationMailer.invite(invitation: invitation, subject: "[TEST] #{@subject}", body: body_for(token, email)).deliver_now
    nil
  end

  private

    def send_to(email)
      return false unless URI::MailTo::EMAIL_REGEXP.match?(email)
      return false if User.exists?(email: email)

      invitation = Invitation.find_or_initialize_by(email: email)
      return false if invitation.persisted? && invitation.accepted_at.present?

      # A new token also renews updated_at, which restarts the three months until it expires
      token = SecureRandom.hex(16)
      invitation.token_digest = Digest::SHA256.hexdigest(token)
      invitation.save!

      InvitationMailer.invite(invitation: invitation, subject: @subject, body: body_for(token, email)).deliver_later
      true
    end

    def body_for(token, email)
      @body.gsub(LINK_PLACEHOLDER, @link_for.call(token, email))
    end
end
