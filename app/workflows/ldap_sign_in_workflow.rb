# The account for a successful LDAP login: found by the directory's email address, or created
# when the feedback space allows it (LdapConfig#auto_create_users). The directory vouches for the
# address, so an unconfirmed account is confirmed. Returns nil when there is no account to use.
class LdapSignInWorkflow
  def initialize(config:, result:)
    @config = config
    @result = result
  end

  def run
    email = @result.email
    return nil unless email && URI::MailTo::EMAIL_REGEXP.match?(email)

    user = User.find_for_authentication(email: email)
    user ||= create_user(email) if @config.auto_create_users
    user&.confirm unless user.nil? || user.confirmed?
    user
  end

  private

    def create_user(email)
      name = @result.name.to_s.truncate(64)
      ActiveRecord::Base.transaction do
        user = User.new(
          email: email, full_name: name.length >= 2 ? name : I18n.t('defaults.user_full_name'),
          password: Devise.friendly_token, has_set_password: false, status: 'active'
        )
        user.skip_confirmation
        user.save!
        Invitation.where(email: email, accepted_at: nil).update_all(accepted_at: Time.current)
        user
      end
    end
end
