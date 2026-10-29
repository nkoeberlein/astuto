# Unlock links in emails (/users/unlock?unlock_token=...) still land here; the page for
# requesting a new link is part of the v2 frontend (/unlock/new).
class UnlocksController < Devise::UnlocksController
  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data

  def new
    flash.keep
    redirect_to spa_unlock_new_path
  end

  # The v2 page posts to /api/app/v1/unlock; an old form lands on the v2 page
  def create
    redirect_to spa_unlock_new_path
  end

  def show
    self.resource = resource_class.unlock_access_by_token(params[:unlock_token])

    if resource.errors.empty?
      set_flash_message!(:notice, :unlocked)
      redirect_to after_unlock_path_for(resource)
    else
      redirect_to spa_unlock_new_path, alert: resource.errors.full_messages.join(', ')
    end
  end
end
