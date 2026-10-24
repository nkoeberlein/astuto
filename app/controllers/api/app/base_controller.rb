module Api
  module App
    # Base controller for the JSON API used by the v2 frontend (frontend/).
    # Authentication: Devise session cookie. Writes need the X-CSRF-Token header
    # (token comes from GET /api/app/v1/session).
    class BaseController < ApplicationController
      skip_before_action :load_tenant_data
      skip_before_action :check_tenant_is_private

      prepend_before_action :set_tenant

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      protected

        def set_tenant
          tenant = get_tenant_from_request(request)
          return render_error(:not_found, 'Feedback space not found') if tenant.nil?
          return render_error(:forbidden, 'Feedback space is not active') if tenant.pending? || tenant.blocked?

          Current.tenant = tenant
          I18n.locale = tenant.locale.presence || I18n.default_locale
        end

        def tenant_setting
          @tenant_setting ||= TenantSetting.first_or_create
        end

        # Content of private feedback spaces is only visible to signed-in users
        def require_access
          return unless tenant_setting.is_private
          return if user_signed_in?

          render_error(:unauthorized, I18n.t('errors.not_logged_in'))
        end

        def render_error(status, message)
          render status: status, json: { error: message }
        end

        def render_not_found
          render_error(:not_found, 'Not found')
        end
    end
  end
end
