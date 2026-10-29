class RegistrationsController < Devise::RegistrationsController
  include ApplicationHelper

  # Needed to have Current.tenant available in Devise's controllers
  prepend_before_action :load_tenant_data

  # Override create to check whether email registration is possible
  def create
    ts = Current.tenant.tenant_setting
    email = sign_up_params[:email]

    # Handle invitations
    is_invitation = sign_up_params[:invitation_token].present?
    invitation = nil
    if is_invitation
      invitation = Invitation.find_acceptable(email: email, token: sign_up_params[:invitation_token])

      if invitation.nil?
        flash[:alert] = t('errors.unauthorized')
        redirect_to new_user_registration_path and return
      end

      ActiveRecord::Base.transaction do
        invitation.accepted_at = Time.now
        invitation.save!

        # Sign up user without confirmation email and log them in
        user = User.new(email: email, full_name: sign_up_params[:full_name], password: sign_up_params[:password], password_confirmation: sign_up_params[:password], status: "active")
        user.skip_confirmation
        user.save!
        sign_in(user)

        flash[:notice] = t('devise.registrations.signed_up')
        redirect_to root_path
      end

      return
    end

    # ... if not an invitation, continue with normal registration ...
    
    # Check if email registration is allowed
    if ts.email_registration_policy == "none_allowed" || (ts.email_registration_policy == "custom_domains_allowed" && !ts.email_domain_allowed?(email))
      flash[:alert] = t('errors.email_domain_not_allowed')
      redirect_to new_user_registration_path and return
    end

    super
  end

  # Sign-up and profile pages are part of the v2 frontend
  def new
    flash.keep
    redirect_to spa_register_path(params.permit(:invitation_token, :email).to_h)
  end

  def edit
    flash.keep
    redirect_to spa_profile_path
  end

  # Override update to check whether provided email is allowed
  def update
    ts = Current.tenant.tenant_setting
    email = account_update_params[:email]

    if email.present? && ts.email_registration_policy == "custom_domains_allowed" && !ts.email_domain_allowed?(email)
      flash[:alert] = t('errors.email_domain_not_allowed')
      redirect_to edit_user_registration_path and return
    end

    # When SMTP is not configured in production, apply email changes immediately
    # instead of locking the user behind an undeliverable reconfirmation email (#476).
    resource.skip_reconfirmation! if Rails.env.production? && ENV['EMAIL_DELIVERY_METHOD'] != 'smtp'

    super
  end

  # Override destroy to soft delete
  def destroy
    resource.status = "deleted"
    resource.email = "#{SecureRandom.alphanumeric(16)}@deleted.com"
    resource.full_name = t('defaults.deleted_user_full_name')
    resource.skip_confirmation
    resource.save
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed
    yield resource if block_given?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
  end

  def send_set_password_instructions
    user = User.find_by_email(params[:email])
    
    if user.present?
      user.send_reset_password_instructions
    end
    
    render json: { success: true } # always return true, even if user not found
  end

  protected

    # Override Devise after inactive sign up path
    def after_inactive_sign_up_path_for(resource)
      if Current.tenant.tenant_setting.is_private
        # Redirect to log in page, since root page only visible to logged in users
        new_user_session_path
      else
        safe_return_to_redirect(session[:return_to]) do
          super
        end
      end
    end
end