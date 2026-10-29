source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.9'

gem 'rake', '13.4.2'

gem 'rails', '8.1.4'

# Default gems that are no longer part of Ruby's standard library (Ruby >= 3.4)
gem 'base64'
gem 'bigdecimal'
gem 'csv'
gem 'drb'
gem 'mutex_m'
gem 'observer'

gem 'pg', '1.7.0'

gem 'puma', '8.0.2'

gem 'jbuilder', '2.15.1'

gem 'bootsnap', '1.26.0', require: false

# HTTP requests
gem 'httparty', '0.24.3'

# Model Context Protocol server (official SDK)
gem 'mcp', '1.8.1'

# Authentication
gem 'devise', '5.0.4'

# Authorization
gem 'pundit', '2.5.2'

# Pagination
gem 'kaminari', '1.3.0'

# DDoS protection
gem 'rack-attack', '6.8.0'

# Slugs
gem 'friendly_id', '5.7.0'


# Serve swagger docs
gem 'rswag-api', '2.17.0'

# We need those gems here, so we can Swaggerize in production
gem 'rswag-specs', '2.17.0'
gem 'rspec-rails', '8.0.4'

# CORS policy
gem 'rack-cors', '3.0.0'

# ActiveJob backend
gem 'sidekiq', '8.1.7'

# Cron jobs with sidekiq
gem 'sidekiq-cron', '2.4.0'

# Template language
gem 'liquid', '5.14.0'

group :development, :test do
  gem 'debug', '1.11.1', platforms: [:mri, :windows], require: false
  
  gem 'factory_bot_rails', '6.5.1'

  # Security checks (bin/ci): known gem vulnerabilities and static analysis
  gem 'bundler-audit', '0.9.3', require: false
  gem 'brakeman', '8.1.0', require: false
end

group :development do
  gem 'web-console', '>= 3.3.0'
end

# File watcher for code reloading in development
gem 'listen', '3.10.1'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]
