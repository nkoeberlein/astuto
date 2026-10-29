module Api::App::V1::SiteSettings
  # Site settings › Webhooks (legacy: /site_settings/webhooks and /webhooks). Admins only.
  # URL and headers may hold secrets: they are stored encrypted (Webhook.encryptor) and only
  # shown to admins.
  class WebhooksController < Api::App::BaseController
    JSON_ERROR = "Webhook body must render valid JSON (tip: use the '| escape_json' filter on string variables)".freeze

    before_action :require_admin
    before_action :check_tenant_subscription, only: [:create, :update, :destroy, :test]

    # GET /api/app/v1/site_settings/webhooks
    def index
      render json: Webhook.order(trigger: :asc, created_at: :desc).map { |webhook| serialize(webhook) }
    end

    # GET /api/app/v1/site_settings/webhooks/variables: template variables per trigger
    def variables
      render json: Webhook.triggers.keys.index_with { |trigger| CreateLiquidTemplateContextWorkflow.variables_for(trigger) }
    end

    # POST /api/app/v1/site_settings/webhooks
    def create
      webhook = Webhook.new
      return unless assign(webhook)
      return render_error(:unprocessable_content, webhook.errors.full_messages.join(', ')) unless webhook.save

      render status: :created, json: serialize(webhook)
    end

    # PATCH /api/app/v1/site_settings/webhooks/:id
    def update
      webhook = Webhook.find(params[:id])
      return unless assign(webhook)
      return render_error(:unprocessable_content, webhook.errors.full_messages.join(', ')) unless webhook.save

      render json: serialize(webhook)
    end

    # DELETE /api/app/v1/site_settings/webhooks/:id
    def destroy
      Webhook.find(params[:id]).destroy!
      head :no_content
    end

    # POST /api/app/v1/site_settings/webhooks/preview { trigger, url, httpBody }:
    # URL and body rendered with example data, without sending anything
    def preview
      trigger = params[:trigger].to_s
      return render_error(:unprocessable_content, I18n.t('errors.unknown')) unless Webhook.triggers.key?(trigger)

      context = CreateLiquidTemplateContextWorkflow.new(webhook_trigger: trigger, is_test: true).run
      url = Liquid::Template.parse(params[:url].to_s, error_mode: :strict).render!(context)
      body = Liquid::Template.parse(params[:httpBody].to_s, error_mode: :strict).render!(context)
      JSON.parse(body) if body.present?

      render json: { url: url, body: body }
    rescue JSON::ParserError => e
      render_error(:unprocessable_content, "#{JSON_ERROR}: #{e.message}")
    rescue Liquid::Error => e
      render_error(:unprocessable_content, e.message)
    end

    # POST /api/app/v1/site_settings/webhooks/:id/test: sends the saved webhook with example data
    def test
      webhook = Webhook.find(params[:id])
      response = RunWebhook.perform_now(webhook_id: webhook.id, current_tenant_id: Current.tenant.id, is_test: true)

      render json: { status: response.code, body: response.body.to_s.truncate(4000) }
    rescue JSON::ParserError => e
      render_error(:unprocessable_content, "#{JSON_ERROR}: #{e.message}")
    rescue Liquid::Error, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, HTTParty::Error => e
      render_error(:unprocessable_content, e.message)
    end

    private

      # Copies the camelCase body onto the webhook; renders a 422 and returns false for unknown enum values
      def assign(webhook)
        if params.key?(:trigger)
          return reject_unknown unless Webhook.triggers.key?(params[:trigger].to_s)

          webhook.trigger = params[:trigger]
        end
        if params.key?(:httpMethod)
          method = "http_#{params[:httpMethod]}"
          return reject_unknown unless Webhook.http_methods.key?(method)

          webhook.http_method = method
        end
        webhook.name = params[:name] if params.key?(:name)
        webhook.description = params[:description] if params.key?(:description)
        webhook.is_enabled = params[:isEnabled] if params.key?(:isEnabled)
        webhook.url = params[:url] if params.key?(:url)
        webhook.http_body = params[:httpBody] if params.key?(:httpBody)
        webhook.http_headers = headers_param.to_json if params.key?(:httpHeaders)
        true
      end

      def reject_unknown
        render_error(:unprocessable_content, I18n.t('errors.unknown'))
        false
      end

      # [{ key, value }] without empty rows, the format RunWebhook reads
      def headers_param
        Array(params[:httpHeaders]).filter_map do |header|
          next unless header.respond_to?(:permit)

          pair = header.permit(:key, :value).to_h
          pair if pair['key'].present? && pair['value'].present?
        end
      end

      def serialize(webhook)
        # Stored as a JSON string by both UIs; older records may hold the array itself
        raw = webhook.http_headers
        headers = raw.is_a?(String) ? (raw.present? ? JSON.parse(raw) : []) : Array(raw)
        {
          id: webhook.id,
          name: webhook.name,
          description: webhook.description,
          isEnabled: webhook.is_enabled,
          trigger: webhook.trigger,
          httpMethod: webhook.http_method.delete_prefix('http_'),
          url: webhook.url,
          httpBody: webhook.http_body,
          httpHeaders: headers.map { |header| { key: header['key'], value: header['value'] } }
        }
      end
  end
end
