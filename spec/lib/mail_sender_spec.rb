require 'rails_helper'

RSpec.describe 'default email sender' do
  around do |example|
    original = ENV.to_h.slice('EMAIL_MAIL_FROM', 'EMAIL_MAIL_REPLY_TO', 'BASE_URL')
    example.run
  ensure
    %w[EMAIL_MAIL_FROM EMAIL_MAIL_REPLY_TO BASE_URL].each { |key| original.key?(key) ? ENV[key] = original[key] : ENV.delete(key) }
  end

  it 'uses EMAIL_MAIL_FROM, otherwise noreply@ the host of BASE_URL' do
    ENV.delete('EMAIL_MAIL_FROM')
    ENV.delete('EMAIL_MAIL_REPLY_TO')
    ENV['BASE_URL'] = 'https://feedback.example.com'
    expect(Rails.application.default_mail_from).to eq('noreply@feedback.example.com')
    expect(Rails.application.default_mail_reply_to).to eq('noreply@feedback.example.com')

    ENV['EMAIL_MAIL_FROM'] = 'hello@example.org'
    ENV['EMAIL_MAIL_REPLY_TO'] = 'support@example.org'
    expect(Rails.application.default_mail_from).to eq('hello@example.org')
    expect(Rails.application.default_mail_reply_to).to eq('support@example.org')
  end

  it 'falls back to localhost for a missing or broken BASE_URL' do
    ENV.delete('EMAIL_MAIL_FROM')
    ENV['BASE_URL'] = 'not a url'
    expect(Rails.application.default_mail_from).to eq('noreply@localhost')
  end
end
