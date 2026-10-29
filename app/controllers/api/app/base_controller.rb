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
      rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_csrf_token

      protected

        def set_tenant
          tenant = get_tenant_from_request(request)
          return render_error(:not_found, 'Feedback space not found') if tenant.nil?
          return render_error(:forbidden, 'Feedback space is not active') if tenant.pending? || tenant.blocked?

          Current.tenant = tenant
          I18n.locale = tenant_locale(tenant, tenant_setting, request)
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

        def require_user
          render_error(:unauthorized, I18n.t('errors.not_logged_in')) unless user_signed_in?
        end

        def require_moderator
          return render_error(:unauthorized, I18n.t('errors.not_logged_in')) unless user_signed_in?

          render_error(:forbidden, I18n.t('errors.unauthorized')) unless current_user.moderator?
        end

        def require_admin
          return render_error(:unauthorized, I18n.t('errors.not_logged_in')) unless user_signed_in?

          render_error(:forbidden, I18n.t('errors.unauthorized')) unless current_user.admin?
        end

        # Sets the "order" column of an Orderable model from a full list of ids (first = 0).
        # Returns false unless the list contains every record exactly once.
        def apply_order(model, ids)
          ids = Array(ids).map(&:to_i)
          return false unless ids.uniq.size == ids.size && ids.sort == model.pluck(:id).sort

          model.transaction do
            ids.each_with_index { |id, index| model.where(id: id).update_all(order: index, updated_at: Time.current) }
          end
          true
        end

        # Posts that are not approved are only visible to moderators
        def find_visible_post(id)
          post = Post.friendly.find(id)
          raise ActiveRecord::RecordNotFound unless post.approved? || current_user&.moderator?

          post
        end

        # Session payload for the frontend (user, tenant settings, CSRF token).
        # OAuth start URLs never use the custom domain: the token_state cookie
        # must be readable on the callback host (as in devise/shared/_o_auths).
        def serialize_session(user)
          Api::App::V1::SessionSerializer.call(
            user: user,
            tenant: Current.tenant,
            tenant_setting: tenant_setting,
            csrf_token: form_authenticity_token,
            oauth_start_url: lambda { |o_auth|
              get_url_for(method(:o_auth_start_url), resource: o_auth.id, disallow_custom_domain: true, options: { reason: 'login' })
            }
          )
        end

        def render_invalid_csrf_token
          render_error(:unprocessable_content, 'Invalid or missing CSRF token. Reload the page and try again.')
        end

        def render_error(status, message)
          render status: status, json: { error: message }
        end

        def render_not_found
          render_error(:not_found, 'Not found')
        end

        def user_not_authorized
          render_error(:forbidden, I18n.t('errors.unauthorized'))
        end
    end
  end
end
