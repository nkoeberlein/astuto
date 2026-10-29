# Daily at 15:00 UTC (config/initializers/sidekiq.rb): sends the recap email to everyone who
# chose a recap frequency in their profile and has notifications on. Weekly recaps go out on
# Mondays, monthly ones on the 1st. Nothing is sent when nothing happened (RecapDigest#any?).
class SendRecapEmails < ActiveJob::Base
  queue_as :default

  HOUR = 15
  PERIODS = { 'daily' => 1.day, 'weekly' => 1.week, 'monthly' => 1.month }.freeze

  def perform(*)
    logger.info { 'Performing SendRecapEmails ActiveJob' }

    to = Time.now.utc.change(hour: HOUR, min: 0, sec: 0)
    frequencies = due_frequencies(Date.today)

    Tenant.where(status: 'active').find_each do |tenant|
      Current.tenant = tenant
      I18n.locale = tenant.locale

      tenant.users
        .where(status: 'active', notifications_enabled: true, recap_notification_frequency: frequencies)
        .find_each do |user|
          from = to - PERIODS.fetch(user.recap_notification_frequency)
          next unless RecapDigest.new(user: user, from: from, to: to).any?

          logger.info { "[#{tenant.subdomain}] Sending recap email to user #{user.id}" }
          UserMailer.recap(user: user, frequency: user.recap_notification_frequency, from: from, to: to).deliver_later
        end
    end
  end

  private

    def due_frequencies(date)
      frequencies = ['daily']
      frequencies << 'weekly' if date.monday?
      frequencies << 'monthly' if date.day == 1
      frequencies
    end
end
