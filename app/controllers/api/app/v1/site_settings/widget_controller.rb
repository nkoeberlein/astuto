module Api::App::V1::SiteSettings
  # Site settings › Widget (admins, docs/widget.md)
  #   GET   /api/app/v1/site_settings/widget
  #   PATCH /api/app/v1/site_settings/widget { enabled, allowedOrigins, autoCreateUsers }
  #   POST  /api/app/v1/site_settings/widget/rotate_secret: new secret, old visitor tokens stop working
  class WidgetController < Api::App::BaseController
    before_action :require_admin

    def show
      config = WidgetConfig.current
      config.save! if config.new_record?
      render json: serialize(config)
    end

    def update
      config = WidgetConfig.current
      config.enabled = params[:enabled] if params.key?(:enabled)
      config.allowed_origins = params[:allowedOrigins].to_s if params.key?(:allowedOrigins)
      config.auto_create_users = params[:autoCreateUsers] if params.key?(:autoCreateUsers)
      return render_error(:unprocessable_content, config.errors.full_messages.join(', ')) unless config.save

      audit('widget.update', nil, changes: config.saved_changes, prefix: 'widget_config') if config.saved_changes?
      render json: serialize(config)
    end

    def rotate_secret
      config = WidgetConfig.current
      config.regenerate_secret
      config.save!
      audit('widget.rotate_secret')
      render json: serialize(config)
    end

    private

      def serialize(config)
        {
          enabled: config.enabled, secret: config.secret, allowedOrigins: config.origins.join("\n"),
          autoCreateUsers: config.auto_create_users
        }
      end
  end
end
