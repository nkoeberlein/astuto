# frozen_string_literal: true

# Background jobs (ActionMailer::MailDeliveryJob, Sidekiq, ActiveJob :async)
# deserialize GlobalID arguments before entering the mailer/job body, at a time
# when Current.tenant is not yet set in the worker thread.
# Unscoping TenantOwnable lookups and setting Current.tenant from the located
# record ensures background mailers (#431, #444) can always deserialize records.
Rails.application.config.to_prepare do
  GlobalID::Locator.use :app do |gid|
    model_class = gid.model_name.constantize
    record = if model_class.included_modules.include?(TenantOwnable)
               model_class.unscoped.find(gid.model_id)
             else
               model_class.find(gid.model_id)
             end
    Current.tenant ||= record.tenant if record.respond_to?(:tenant)
    record
  end
end
