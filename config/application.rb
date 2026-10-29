require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Active Storage is not used (files must not live in it, see AGENTS.md)
    config.active_storage.variant_processor = :disabled

    # Always read SECRET_KEY_BASE from the environment, also in development and test.
    # Webhook encryption and API key digests are derived from it, so it must not change.
    config.secret_key_base = ENV['SECRET_KEY_BASE'] if ENV['SECRET_KEY_BASE'].present?

    # Set default locale
    config.i18n.default_locale = :en

    # Set sidekiq as ActiveJob backend
    config.active_job.queue_adapter = ENV["ACTIVE_JOB_BACKEND"] == "sidekiq" ? :sidekiq : :async

    # Never serve public/**/index.html for a bare directory path. Otherwise the
    # static file server answers /next/ with public/next/index.html itself, skipping
    # the redirect to / and SpaController (meta tags, Content Security Policy).
    config.public_file_server.index_name = "no-directory-index"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # If configured, add trusted proxy to the list of trusted proxies
    config.middleware.insert_after ActionDispatch::RemoteIp, Rack::Attack
    if ENV["TRUSTED_PROXY"]
      config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + [IPAddr.new(ENV["TRUSTED_PROXY"])]
    end

    def base_url
      ENV["BASE_URL"]
    end

    # Sender of all emails: EMAIL_MAIL_FROM, otherwise noreply@<host of BASE_URL>
    # (no longer the addresses of the discontinued astuto.io service)
    def default_mail_from
      ENV['EMAIL_MAIL_FROM'].presence || "noreply@#{base_url_host}"
    end

    def default_mail_reply_to
      ENV['EMAIL_MAIL_REPLY_TO'].presence || default_mail_from
    end

    def base_url_host
      URI.parse(base_url.to_s).host.presence || 'localhost'
    rescue URI::InvalidURIError
      'localhost'
    end

    def multi_tenancy?
      ENV["MULTI_TENANCY"] == "true"
    end

    def posts_per_page
      15
    end

    def trial_period_days
      ENV.key?("TRIAL_PERIOD_DAYS") ? ENV["TRIAL_PERIOD_DAYS"].to_i.days : 7.days
    end

    def stripe_secret_key
      ENV["STRIPE_SECRET_KEY"]
    end

    def stripe_public_key
      ENV["STRIPE_PUBLIC_KEY"]
    end

    def stripe_endpoint_secret
      ENV["STRIPE_ENDPOINT_SECRET"]
    end

    def stripe_manage_subscription_url
      ENV["STRIPE_MANAGE_SUBSCRIPTION_URL"]
    end

    def stripe_monthly_lookup_key
      ENV["STRIPE_MONTHLY_LOOKUP_KEY"]
    end

    def stripe_yearly_lookup_key
      ENV["STRIPE_YEARLY_LOOKUP_KEY"]
    end

    def sidekiq_enabled?
      ENV["ACTIVE_JOB_BACKEND"] == "sidekiq"
    end
  end
end
