# A new feedback space with the welcome boards and an owner whose email address is confirmed.
# The owner gets a random password, shown once to whoever created the space (instance admin
# page, `bin/rails tenants:create`). Returns the tenant; errors are on #errors.
class CreateTenantWorkflow
  attr_reader :tenant, :owner, :password, :errors

  def initialize(subdomain:, site_name: nil, owner_email:, owner_name: nil, locale: nil)
    @subdomain = subdomain.to_s.strip.downcase
    @site_name = site_name.to_s.strip.presence || @subdomain
    @owner_email = owner_email.to_s.strip
    @owner_name = owner_name.to_s.strip.presence || I18n.t('defaults.user_full_name')
    @locale = locale.to_s.presence || I18n.default_locale.to_s
    @errors = []
  end

  def run
    return fail!("#{@subdomain} is reserved") if RESERVED_SUBDOMAINS.include?(@subdomain)

    @password = SecureRandom.base58(20)
    previous_tenant = Current.tenant
    ActiveRecord::Base.transaction do
      @tenant = Tenant.create!(site_name: @site_name, subdomain: @subdomain, locale: @locale, status: 'active')
      Current.tenant = @tenant
      @owner = User.create!(
        full_name: @owner_name, email: @owner_email, password: @password,
        role: 'owner', confirmed_at: Time.current
      )
      CreateWelcomeEntitiesWorkflow.new.run
    end
    @tenant
  rescue ActiveRecord::RecordInvalid => e
    @tenant = nil
    fail!(e.record.errors.full_messages.join(', '))
  ensure
    Current.tenant = previous_tenant
  end

  def success?
    @tenant.present? && @errors.empty?
  end

  private

    def fail!(message)
      @errors << message
      nil
    end
end
