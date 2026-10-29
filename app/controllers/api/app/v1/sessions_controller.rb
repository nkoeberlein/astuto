module Api::App::V1
  class SessionsController < Api::App::BaseController
    include Devise::Controllers::Rememberable

    # GET /api/app/v1/session
    def show
      render json: serialize_session(current_user)
    end

    # POST /api/app/v1/session { email, password, rememberMe }
    def create
      user = User.find_for_authentication(email: params[:email].to_s.strip)
      authenticated = user&.valid_for_authentication? { user.valid_password?(params[:password].to_s) }

      # Lockable: failed attempts are counted (and the account eventually locked)
      # through valid_for_authentication?, so the lockout applies here too.
      # unauthenticated_message is :locked, :last_attempt (warning before the
      # lock) or :invalid, as in Devise's failure app.
      unless authenticated
        reason = user ? user.unauthenticated_message : :invalid
        return render_error(
          :unauthorized,
          I18n.t("devise.failure.#{reason}", authentication_keys: I18n.t('common.forms.auth.email'))
        )
      end

      return render_error(:forbidden, I18n.t('devise.failure.unconfirmed')) unless user.confirmed?
      return render_error(:forbidden, user.inactive_message) unless user.active_for_authentication?

      remember = ActiveModel::Type::Boolean.new.cast(params[:rememberMe])
      if user.two_factor_enabled?
        # Second step: POST /api/app/v1/session/two_factor with a code
        start_two_factor_login(user, remember: remember)
        return render status: :accepted, json: { twoFactorRequired: true }
      end

      sign_in(:user, user)
      remember_me(user) if remember

      render json: serialize_session(user)
    end

    # POST /api/app/v1/session/ldap { login, password, rememberMe }: login with the company
    # directory (LDAP / Active Directory). Same answers as POST /session, including the
    # two-factor step; wrong credentials get one generic message.
    def ldap
      config = LdapConfig.current
      return render_not_found unless config.usable?

      result = config.authenticate(params[:login], params[:password])
      user = result && LdapSignInWorkflow.new(config: config, result: result).run
      return render_error(:unauthorized, I18n.t('ldap.invalid_login', label: config.label)) unless user
      return render_error(:unauthorized, I18n.t('devise.failure.locked')) if user.access_locked?
      return render_error(:forbidden, user.inactive_message) unless user.active_for_authentication?

      remember = ActiveModel::Type::Boolean.new.cast(params[:rememberMe])
      if user.two_factor_enabled?
        start_two_factor_login(user, remember: remember)
        return render status: :accepted, json: { twoFactorRequired: true }
      end

      sign_in(:user, user)
      remember_me(user) if remember
      render json: serialize_session(user)
    end

    # POST /api/app/v1/session/two_factor { code }: second step of a login with 2FA, after the
    # password (POST /session) or an OAuth provider. Wrong codes count as failed logins (Lockable).
    def two_factor
      user = pending_two_factor_user
      return render_error(:unauthorized, I18n.t('two_factor.login_expired')) unless user
      return render_error(:unauthorized, I18n.t('devise.failure.locked')) if user.access_locked?

      unless user.verify_two_factor(params[:code])
        count_failed_two_factor_attempt(user)
        return render_error(:unauthorized, I18n.t('two_factor.invalid_code'))
      end

      remember = session.delete(:two_factor_remember)
      clear_two_factor_login
      user.update_column(:failed_attempts, 0) if user.failed_attempts.positive?
      sign_in(:user, user)
      remember_me(user) if remember

      render json: serialize_session(user)
    end

    # DELETE /api/app/v1/session
    def destroy
      forget_me(current_user) if user_signed_in?
      sign_out(:user)

      render json: serialize_session(nil)
    end
  end
end
