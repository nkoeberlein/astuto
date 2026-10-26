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

      sign_in(:user, user)
      remember_me(user) if ActiveModel::Type::Boolean.new.cast(params[:rememberMe])

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
