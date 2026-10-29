module Api::App::V1::SiteSettings
  # Site settings › General › "Send test email" (admins). Sends at once and reports delivery
  # errors (e.g. SMTP authentication) even when EMAIL_RAISE_DELIVERY_ERRORS is false.
  class TestEmailsController < Api::App::BaseController
    before_action :require_admin

    # POST /api/app/v1/site_settings/test_email
    def create
      message = AdminMailer.test_email(user: current_user).message
      message.raise_delivery_errors = true
      message.deliver

      render json: { sentTo: current_user.email, deliveryMethod: ActionMailer::Base.delivery_method.to_s, from: Array(message.from).join(', ') }
    rescue StandardError => e
      Rails.logger.error { "[mail] Test email to #{current_user.email} failed: #{e.class}: #{e.message}" }
      render_error(:unprocessable_content, "#{e.class}: #{e.message}")
    end
  end
end
