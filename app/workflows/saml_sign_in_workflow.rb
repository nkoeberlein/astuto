# The account for a valid SAML response: found by email, or created when the feedback space
# allows it (SamlConfig#auto_create_users). Returns nil for unknown, blocked or deleted accounts.
# Signing in is up to the controller.
class SamlSignInWorkflow
  def initialize(config:, response:)
    @config = config
    @response = response
  end

  def run
    email = @config.email_from(@response)
    return nil unless email && URI::MailTo::EMAIL_REGEXP.match?(email)

    user = User.find_for_authentication(email: email) || (create_user(email) if @config.auto_create_users)
    user if user&.active_for_authentication?
  end

  private

    def create_user(email)
      ActiveRecord::Base.transaction do
        user = User.new(
          email: email,
          full_name: @config.name_from(@response).to_s.truncate(64).presence || I18n.t('defaults.user_full_name'),
          password: Devise.friendly_token,
          has_set_password: false,
          status: 'active'
        )
        user.full_name = I18n.t('defaults.user_full_name') if user.full_name.length < 2
        user.skip_confirmation
        user.save!

        Invitation.where(email: email, accepted_at: nil).update_all(accepted_at: Time.current)
        user
      end
    end
end
