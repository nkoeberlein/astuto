source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.13'

gem 'rake', '13.2.1'

gem 'rails', '7.2.4'

# Asset pipeline (no longer bundled with Rails 7)
gem 'sprockets-rails', '3.5.2'

# Default gems that are no longer part of Ruby's standard library (Ruby >= 3.4)
gem 'base64'
gem 'bigdecimal'
gem 'csv'
gem 'drb'
gem 'mutex_m'
gem 'observer'

gem 'pg', '1.3.5'

gem 'puma', '5.6.9'

gem 'turbolinks', '5.2.1'

gem 'jbuilder', '2.15.1'

gem 'bootsnap', '1.12.0', require: false

# CSS
gem "cssbundling-rails", '1.1.2'

# JavaScript
gem 'jsbundling-rails', '1.1.1'

# HTTP requests
gem 'httparty', '0.21.0'

# Authentication
gem 'devise', '4.9.4'

# Authorization
gem 'pundit', '2.2.0'

# I18n (forward locales to JS)
gem 'i18n-js', '3.9.2'

# React
gem 'react-rails', '2.6.2'

# Pagination
gem 'kaminari', '1.2.2'

# DDoS protection
gem 'rack-attack', '6.7.0'

# Slugs
gem 'friendly_id', '5.5.1'

# Billing
gem 'stripe', '11.2.0'

# Serve swagger docs
gem 'rswag-api', '2.15.0'

# We need those gems here, so we can Swaggerize in production
gem 'rswag-specs', '2.15.0'
gem 'rspec-rails', '7.1.1'
gem 'capybara', '3.40.0'

# CORS policy
gem 'rack-cors', '2.0.2'

# ActiveJob backend
gem 'sidekiq', '7.3.5'

# Cron jobs with sidekiq
gem 'sidekiq-cron', '2.0.1'

# Template language
gem 'liquid', '5.5.1'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  
  gem 'factory_bot_rails', '5.0.2'
end

group :development do
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'selenium-webdriver', '4.17.0'

  # Retry flaky Capybara tests
  gem 'rspec-retry', '0.6.2'
end

# If not bundled, webpack compilation in production fails
gem 'listen', '3.5.1'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
