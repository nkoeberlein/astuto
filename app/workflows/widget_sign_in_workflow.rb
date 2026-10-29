# The account for a widget visitor (claims from WidgetToken): found by the customer's user id
# (widget_external_id), else by email (and then linked to that id), else created when the
# feedback space allows it. The customer's app vouches for the address, so the account counts as
# confirmed. Staff accounts are refused: whoever holds the widget secret must not become a
# moderator or admin. Returns [user, nil] or [nil, error key].
class WidgetSignInWorkflow
  def initialize(config:, claims:)
    @config = config
    @claims = claims
  end

  def run
    email = @claims['email'].to_s.strip.downcase
    return [nil, 'invalid_token'] unless URI::MailTo::EMAIL_REGEXP.match?(email)

    external_id = @claims['id'].presence&.to_s&.truncate(255, omission: '')
    user = external_id && User.find_by(widget_external_id: external_id)
    user ||= User.find_for_authentication(email: email)
    return [nil, 'linked_elsewhere'] if user && external_id && user.widget_external_id.present? && user.widget_external_id != external_id

    user ||= create_user(email, external_id) if @config.auto_create_users
    return [nil, 'no_account'] unless user
    return [nil, 'staff_account'] if user.moderator?
    return [nil, 'blocked'] unless user.active?

    update(user, external_id)
    # Locked after too many wrong passwords
    return [nil, 'blocked'] unless user.active_for_authentication?

    [user, nil]
  end

  private

    def name
      @claims['name'].to_s.strip.truncate(64).presence
    end

    def update(user, external_id)
      user.widget_external_id = external_id if external_id && user.widget_external_id.blank?
      user.full_name = name if name && name.length >= 2
      user.skip_confirmation unless user.confirmed?
      user.save! if user.changed?
    end

    def create_user(email, external_id)
      ActiveRecord::Base.transaction do
        user = User.new(
          email: email, full_name: name && name.length >= 2 ? name : I18n.t('defaults.user_full_name'),
          password: Devise.friendly_token, has_set_password: false, status: 'active', widget_external_id: external_id
        )
        user.skip_confirmation
        user.save!
        Invitation.where(email: email, accepted_at: nil).update_all(accepted_at: Time.current)
        user
      end
    end
end
