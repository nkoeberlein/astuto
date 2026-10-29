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

  # The v2 reset page uses /api/app/v1/password; an old form posting here lands there
  def update
    redirect_to spa_password_reset_path
  end
end