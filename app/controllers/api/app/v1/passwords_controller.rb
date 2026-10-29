module Api::App::V1
  class PasswordsController < Api::App::BaseController
    # POST /api/app/v1/password { email }
    def create
      email = params[:email].to_s.strip
      return render_error(:unprocessable_content, I18n.t('common.validations.email')) unless URI::MailTo::EMAIL_REGEXP.match?(email)

      # The email links to the v2 reset page. The answer is the same whether
      # or not the address exists, so it does not reveal accounts.
      User.find_for_authentication(email: email)&.send_next_reset_password_instructions
      render json: { message: I18n.t('devise.passwords.send_paranoid_instructions') }
    end

    # PATCH /api/app/v1/password { resetPasswordToken, password, passwordConfirmation }
    def update
      user = User.reset_password_by_token(
        reset_password_token: params[:resetPasswordToken].to_s,
        password: params[:password].to_s,
        password_confirmation: params[:passwordConfirmation].to_s
      )

      return render_error(:unprocessable_content, user.errors.full_messages.join(', ')) unless user.errors.empty?

      # Like Devise::PasswordsController#update: a reset proves access to the
      # email address, so it also unlocks an account locked by failed logins
      user.unlock_access! if user.respond_to?(:unlock_strategy_enabled?) && user.unlock_strategy_enabled?(:email)
      user.update!(has_set_password: true) unless user.has_set_password?
      signed_in_user = nil
      # With 2FA the reset alone does not sign in: the code is still needed (normal login)
      if user.active_for_authentication? && !user.two_factor_enabled?
        sign_out(:user)
        sign_in(:user, user)
        signed_in_user = user
      end

      render json: {
        message: I18n.t('devise.passwords.updated'),
        session: serialize_session(signed_in_user)
      }
    end
  end
end
