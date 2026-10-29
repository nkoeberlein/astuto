module Api::App::V1
  # POST /api/app/v1/widget/session { token }: the widget (/embed) trades the visitor token
  # signed by the customer's app (WidgetToken) for an access token it sends as
  # "Authorization: Bearer ..." (see Api::App::BaseController). docs/widget.md
  class WidgetSessionsController < Api::App::BaseController
    # The iframe has no cookie session a CSRF token could belong to. Nothing here touches the
    # session: the access token only comes back in the response, so a forged request gains nothing.
    skip_forgery_protection

    def create
      config = WidgetConfig.find_by(enabled: true)
      return render_error(:not_found, I18n.t('widget.errors.disabled')) unless config

      claims = WidgetToken.decode(params[:token].to_s, config.secret)
      user, error = WidgetSignInWorkflow.new(config: config, claims: claims).run
      return render_error(:forbidden, I18n.t("widget.errors.#{error}")) unless user

      render json: {
        accessToken: self.class.widget_access_token(user),
        expiresAt: WIDGET_TOKEN_LIFETIME.from_now.iso8601
      }
    rescue WidgetToken::Invalid => e
      Rails.logger.info { "[widget] token refused for #{Current.tenant.subdomain}: #{e.message}" }
      render_error(:unauthorized, I18n.t('widget.errors.invalid_token'))
    end
  end
end
