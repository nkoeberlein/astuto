class SessionsController < Devise::SessionsController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data

  # The login page is part of the v2 frontend; Devise and confirmation links still land here
  def new
    flash.keep
    redirect_to spa_login_path
  end
end
