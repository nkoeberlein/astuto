module Api::App::V1
  class ConfirmationsController < Api::App::BaseController
    # POST /api/app/v1/confirmation { email }
    # Sends the confirmation link again. The answer is the same whether or not the address
    # exists or is already confirmed, so it does not reveal accounts.
    def create
      email = params[:email].to_s.strip
      return render_error(:unprocessable_content, I18n.t('common.validations.email')) unless URI::MailTo::EMAIL_REGEXP.match?(email)

      user = User.find_for_authentication(email: email) || User.find_by(unconfirmed_email: email.downcase)
      user.send_confirmation_instructions if user && (!user.confirmed? || user.pending_reconfirmation?)
      render json: { message: I18n.t('devise.confirmations.send_paranoid_instructions') }
    end
  end
end
