class PasswordsController < Devise::PasswordsController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data

  # Needed for OAuth users (otherwise an already logged in user wouldn't be able to reset their password)
  skip_before_action :require_no_authentication, :only => [:edit, :update]

  # Forgot and reset password pages are part of the v2 frontend; reset links of older
  # emails (/users/password/edit?reset_password_token=...) still land here
  def new
    flash.keep
    redirect_to spa_password_forgot_path
  end

  def edit
    flash.keep
    redirect_to spa_password_reset_path(reset_password_token: params[:reset_password_token])
  end

  def update
    super

    if resource.errors.empty?
      resource.update!(has_set_password: true) unless resource.has_set_password?

      # See: https://stackoverflow.com/a/22110985/1857435
      sign_out(resource_name)
      sign_in(resource_name, resource)
    end
  end
end