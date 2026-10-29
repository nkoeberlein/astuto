module Api::App::V1
  class UnlocksController < Api::App::BaseController
    # POST /api/app/v1/unlock { email }
    # Sends the unlock link again for an account locked by failed logins. The answer is the
    # same whether or not the address exists or is locked, so it does not reveal accounts.
    def create
      email = params[:email].to_s.strip
      return render_error(:unprocessable_content, I18n.t('common.validations.email')) unless URI::MailTo::EMAIL_REGEXP.match?(email)

      user = User.find_for_authentication(email: email)
      user.send_unlock_instructions if user&.access_locked?
      render json: { message: I18n.t('devise.unlocks.send_paranoid_instructions') }
    end
  end
end
