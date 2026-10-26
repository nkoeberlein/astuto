# Credentials of the admin account that db/seeds.rb creates on a fresh install.
# ADMIN_EMAIL and ADMIN_PASSWORD set them. Without ADMIN_PASSWORD, development
# keeps the documented "password"; every other environment gets a random one,
# so no installation starts with a password everybody knows.
class DefaultAdminCredentials
  DEFAULT_EMAIL = 'admin@example.com'.freeze
  DEVELOPMENT_PASSWORD = 'password'.freeze

  attr_reader :email, :password

  def initialize(env: ENV, rails_env: Rails.env)
    @email = env['ADMIN_EMAIL'].to_s.strip.presence || DEFAULT_EMAIL
    @password_from_env = env['ADMIN_PASSWORD'].to_s.presence
    @password = @password_from_env ||
                (rails_env.to_s == 'development' ? DEVELOPMENT_PASSWORD : SecureRandom.alphanumeric(20))
  end

  # True when the password was chosen by the admin; it is then not printed
  def password_from_env?
    @password_from_env.present?
  end
end
