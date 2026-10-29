# Confirmation links in emails (/users/confirmation?confirmation_token=...) still land here; the
# page for requesting a new link is part of the v2 frontend (/confirmation/new).
class ConfirmationsController < Devise::ConfirmationsController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data

  def new
    flash.keep
    redirect_to spa_confirmation_new_path
  end

  # The v2 page posts to /api/app/v1/confirmation; an old form lands on the v2 page
  def create
    redirect_to spa_confirmation_new_path
  end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      redirect_to after_confirmation_path_for(resource_name, resource)
    else
      # e.g. "Email was already confirmed" or an expired link
      redirect_to spa_confirmation_new_path, alert: resource.errors.full_messages.join(', ')
    end
  end
end
