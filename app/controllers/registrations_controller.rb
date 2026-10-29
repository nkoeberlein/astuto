# Sign-up and profile are part of the v2 frontend (/register, /profile, app API). Devise's
# routes stay for its URL helpers and old links; their HTML forms are gone.
class RegistrationsController < Devise::RegistrationsController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data

  def new
    flash.keep
    redirect_to spa_register_path(params.permit(:invitation_token, :email).to_h)
  end

  def edit
    flash.keep
    redirect_to spa_profile_path
  end

  # Old forms posting here land on the v2 pages, which use /api/app/v1/registration and /profile
  def create
    redirect_to spa_register_path
  end

  def update
    redirect_to spa_profile_path
  end

  def destroy
    redirect_to spa_profile_path
  end
end
