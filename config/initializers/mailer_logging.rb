# frozen_string_literal: true

# Always log email delivery errors, even when config.action_mailer.raise_delivery_errors = false.
ActiveSupport::Notifications.subscribe('deliver.action_mailer') do |*_args, payload|
  exception_type, exception_message = payload[:exception]
  next unless exception_type

  Rails.logger.error(
    "[ActionMailer] Delivery failed for #{payload[:mailer]} (to=#{Array(payload[:to]).join(', ')}): " \
    "#{exception_type}: #{exception_message}"
  )
end
