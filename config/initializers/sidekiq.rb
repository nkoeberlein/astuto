if ENV['ACTIVE_JOB_BACKEND'] == 'sidekiq'
  # REDIS_URL plus an optional REDIS_PASSWORD, passed separately so special characters need no
  # escaping and rediss:// works (it used to be spliced into the URL at a fixed position)
  redis_options = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'), password: ENV['REDIS_PASSWORD'].presence }.compact

  Sidekiq.configure_server do |config|
    config.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
    config.redis = redis_options
  end

  Sidekiq.configure_client do |config|
    config.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
    config.redis = redis_options
  end

  # Sidekiq Cron
  if ENV['IS_SIDEKIQ'] == 'true'
    Sidekiq::Cron.configure do |config|
      # config.cron_schedule_file doesn't work for some reason so we have to create the cron jobs manually
      Sidekiq::Cron::Job.create(
        name: 'SendRecapEmails Job',
        cron: ENV.fetch('SEND_RECAP_EMAIL_CRON') { '0 15 * * *' }, # defaults to every day at 15:00
        class: 'SendRecapEmails'
      )

      config.cron_poll_interval = Rails.env.production? ? 30 : 15
      config.cron_history_size = 50
      config.default_namespace = 'default'
      config.natural_cron_parsing_mode = :strict

      # Handles the case when the Sidekiq process was down for a while and the cron job should have run (set to 10 minutes, i.e. 600 seconds)
      # This could happen during the deployment of a new version of the application
      config.reschedule_grace_period = 600
    end
  end
end
