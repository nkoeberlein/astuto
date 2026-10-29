module InstanceAdmin
  class TenantsController < BaseController
    before_action :set_tenant, only: [:edit, :update, :block, :unblock, :destroy]

    def index
      @tenants = Tenant.order(:subdomain)
      @user_counts = User.unscoped.group(:tenant_id).count
      @post_counts = Post.unscoped.group(:tenant_id).count
    end

    def new
      @form = {}
    end

    def create
      @form = create_params
      @workflow = CreateTenantWorkflow.new(
        subdomain: @form[:subdomain], site_name: @form[:site_name], owner_email: @form[:owner_email],
        owner_name: @form[:owner_name], locale: @form[:locale]
      )
      @tenant = @workflow.run
      return render(:created, status: :created) if @workflow.success?

      flash.now[:alert] = @workflow.errors.join(', ')
      render :new, status: :unprocessable_content
    end

    def edit; end

    def update
      attributes = update_params.to_h
      attributes['custom_domain'] = attributes['custom_domain'].to_s.strip.downcase.presence if attributes.key?('custom_domain')

      if @tenant.update(attributes)
        redirect_to instance_admin_tenants_path, notice: t('instance_admin.tenants.updated', subdomain: @tenant.subdomain)
      else
        flash.now[:alert] = @tenant.errors.full_messages.join(', ')
        render :edit, status: :unprocessable_content
      end
    end

    def block
      @tenant.update!(status: 'blocked')
      redirect_to instance_admin_tenants_path, notice: t('instance_admin.tenants.blocked', subdomain: @tenant.subdomain)
    end

    def unblock
      @tenant.update!(status: 'active')
      redirect_to instance_admin_tenants_path, notice: t('instance_admin.tenants.unblocked', subdomain: @tenant.subdomain)
    end

    # Deletes the feedback space with all its data; the subdomain has to be typed as confirmation
    def destroy
      unless params[:confirm_subdomain].to_s.strip.downcase == @tenant.subdomain
        redirect_to edit_instance_admin_tenant_path(@tenant), alert: t('instance_admin.tenants.confirm_mismatch')
        return
      end

      Current.set(tenant: @tenant) { @tenant.destroy! }
      redirect_to instance_admin_tenants_path, notice: t('instance_admin.tenants.deleted', subdomain: @tenant.subdomain)
    end

    private

      def set_tenant
        @tenant = Tenant.find(params[:id])
      end

      def create_params
        params.require(:tenant).permit(:subdomain, :site_name, :owner_email, :owner_name, :locale)
      end

      def update_params
        params.require(:tenant).permit(:site_name, :custom_domain, :locale)
      end
  end
end
