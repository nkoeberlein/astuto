# Create tenant
tenant = Tenant.create(
  site_name: 'Default Site Name',
  subdomain: 'default',
  status: 'active'
)
Current.tenant = tenant

# Create an admin user and confirm its email automatically
credentials = DefaultAdminCredentials.new
owner = User.create!(
  full_name: 'Admin',
  email: credentials.email,
  password: credentials.password,
  role: 'owner',
  confirmed_at: Time.zone.now
)

tenant.tenant_billing = TenantBilling.create!(status: 'perpetual')

CreateWelcomeEntitiesWorkflow.new().run

# Let the user know how to log in with admin account
puts "A default tenant has been created with name #{tenant.site_name}"
puts 'A default admin account has been created. Credentials:'
puts "-> email: #{owner.email}"
if credentials.password_from_env?
  puts '-> password: the one set in ADMIN_PASSWORD'
else
  puts "-> password: #{credentials.password}"
  puts '   Change it after the first login, or set ADMIN_EMAIL / ADMIN_PASSWORD before the first start.'
end