class UnlocksController < Devise::UnlocksController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data
end