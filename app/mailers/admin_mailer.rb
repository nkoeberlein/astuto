# Emails for administrators of a feedback space
class AdminMailer < ApplicationMailer
  # Site settings › General › "Send test email": checks the email configuration
  def test_email(user:)
    Current.tenant = user.tenant
    @user = user
    @delivery_method = ActionMailer::Base.delivery_method

    mail(to: user.email, subject: I18n.t('mailers.admin.test_email.subject', site_name: Current.tenant.site_name))
  end
end
