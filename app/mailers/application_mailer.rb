class ApplicationMailer < ActionMailer::Base
  layout 'mailer'
  helper :application

  after_action :set_mail_from_for_multitenancy
  
  def set_mail_from_for_multitenancy
    if Rails.application.multi_tenancy?
      address = Rails.application.default_mail_from
      from = "#{Current.tenant.site_name} <#{address}>"

      # Set a specific 'from' for the Devise::Mailer#confirmation_instructions method on tenant signup
      if self.class.name == "Devise::Mailer" && action_name == "confirmation_instructions" && Current.tenant.users.count == 1
        from = "#{AstutoProject::NAME} <#{address}>"
      end

      mail.from = from
    end
  end
end
