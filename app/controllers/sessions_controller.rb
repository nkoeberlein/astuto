class SessionsController < Devise::SessionsController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data
  # No password logins here (they would skip two-factor authentication)
  skip_before_action :allow_params_authentication!, only: :create

  # The login page is part of the v2 frontend; Devise and confirmation links still land here
  def new
    flash.keep
    redirect_to spa_login_path
  end

  # Logins go through the v2 page and /api/app/v1/session (which knows two-factor
  # authentication); a form posting here lands on the login page
  def create
    redirect_to spa_login_path
  end
end
