module Api::App::V1::SiteSettings
  # Site settings › Authentication: OAuth providers (legacy: /site_settings/authentication,
  # /o_auths and /o_auths/:id/tenant_default_o_auths). Admins only.
  # Default providers (tenant_id nil, set up by the instance) are read-only here; a tenant can
  # only switch them on or off for itself. The client secret never leaves the server.
  class OAuthsController < Api::App::BaseController
    FIELDS = %w[name logo is_enabled client_id client_secret authorize_url token_url profile_url scope json_user_name_path json_user_email_path].freeze

    before_action :require_admin
    before_action :check_tenant_subscription, except: [:index]

    # GET /api/app/v1/site_settings/o_auths
    def index
      o_auths = OAuth.include_all_defaults.order(tenant_id: :asc, created_at: :asc)
      render json: o_auths.map { |o_auth| serialize(o_auth) }
    end

    # POST /api/app/v1/site_settings/o_auths { name, clientId, clientSecret, ... }
    def create
      o_auth = OAuth.new(o_auth_params)
      return render_error(:unprocessable_content, o_auth.errors.full_messages.join(', ')) unless o_auth.save

      render status: :created, json: serialize(o_auth)
    end

    # PATCH /api/app/v1/site_settings/o_auths/:id (a blank clientSecret keeps the current one)
    def update
      o_auth = OAuth.find(params[:id])
      return render_error(:unprocessable_content, o_auth.errors.full_messages.join(', ')) unless o_auth.update(o_auth_params)

      render json: serialize(o_auth)
    end

    # DELETE /api/app/v1/site_settings/o_auths/:id
    def destroy
      OAuth.find(params[:id]).destroy!
      head :no_content
    end

    # PUT /api/app/v1/site_settings/o_auths/:id/default { enabled } (default providers only)
    def default
      o_auth = OAuth.include_only_defaults.find(params[:id])
      enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
      existing = TenantDefaultOAuth.find_by(o_auth_id: o_auth.id)

      if enabled && existing.nil?
        TenantDefaultOAuth.create!(o_auth_id: o_auth.id)
      elsif !enabled
        existing&.destroy!
      end

      render json: serialize(o_auth)
    end

    private

      def o_auth_params
        FIELDS.each_with_object({}) do |field, attributes|
          key = field.camelize(:lower)
          next unless params.key?(key)
          next if field == 'client_secret' && params[key].blank? && action_name == 'update'

          attributes[field] = params[key]
        end
      end

      def serialize(o_auth)
        default = o_auth.is_default?
        {
          id: o_auth.id,
          name: o_auth.name,
          logo: o_auth.logo,
          isEnabled: default ? o_auth.default_o_auth_is_enabled : o_auth.is_enabled,
          isDefault: default,
          clientId: default ? nil : o_auth.client_id,
          authorizeUrl: default ? nil : o_auth.authorize_url,
          tokenUrl: default ? nil : o_auth.token_url,
          profileUrl: default ? nil : o_auth.profile_url,
          scope: default ? nil : o_auth.scope,
          jsonUserNamePath: default ? nil : o_auth.json_user_name_path,
          jsonUserEmailPath: default ? nil : o_auth.json_user_email_path,
          callbackUrl: o_auth.callback_url,
          testUrl: "/o_auths/#{o_auth.id}/start?reason=test"
        }
      end
  end
end
