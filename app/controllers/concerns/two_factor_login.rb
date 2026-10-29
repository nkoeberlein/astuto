# Second step of a login with two-factor authentication. After the password (app API) or the
# OAuth provider, the session remembers who is signing in for a few minutes; the user is signed
# in only after POST /api/app/v1/session/two_factor with a valid code.
module TwoFactorLogin
  extend ActiveSupport::Concern

  TWO_FACTOR_LOGIN_WINDOW = 5.minutes

  private

    def start_two_factor_login(user, remember: false)
      session[:two_factor_user_id] = user.id
      session[:two_factor_started_at] = Time.current.to_i
      session[:two_factor_remember] = remember
    end

    def pending_two_factor_user
      id = session[:two_factor_user_id]
      started = session[:two_factor_started_at].to_i
      return nil if id.blank? || Time.current.to_i - started > TWO_FACTOR_LOGIN_WINDOW

      User.find_by(id: id)
    end

    def clear_two_factor_login
      session.delete(:two_factor_user_id)
      session.delete(:two_factor_started_at)
      session.delete(:two_factor_remember)
    end

    # Wrong codes lock the account like wrong passwords (Devise Lockable)
    def count_failed_two_factor_attempt(user)
      return unless User.lock_strategy_enabled?(:failed_attempts)

      user.increment_failed_attempts
      return if user.failed_attempts.to_i < User.maximum_attempts

      user.lock_access!
      clear_two_factor_login
    end
end
