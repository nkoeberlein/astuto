class RunWebhook < ActiveJob::Base
  queue_as :webhooks

  TIMEOUT_SECONDS = 15

  # entities is a hash with entity_name as key and entity_id as value (entity_name will be mapped to an ActiveRecord class)
  def perform(webhook_id:, current_tenant_id:, is_test: false, entities: {})
    Current.tenant = Tenant.find(current_tenant_id)

    logger.info { "[#{Current.tenant.subdomain}] Performing RunWebhook ActiveJob for webhook ID #{webhook_id}" }

    # Find webhook from DB
    webhook = Webhook.find(webhook_id)

    # Skip if webhook is disabled and is not a test
    return if !is_test && !webhook.is_enabled

    # Load entities from DB
    loaded_entities = {}
    entities.each do |entity_name, entity_id|
      entity_class = map_entity_name_to_class(entity_name)

      # If there is an ActiveRecord class for that entity_name, load it from DB
      # Otherwise, just pass the ID (this is the special case of trigger 'delete_post')
      if entity_class
        loaded_entities[entity_name] = entity_class.find(entity_id)
      else
        loaded_entities[entity_name] = entity_id
      end
    end

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      url, http_body = render_request(webhook, is_test, loaded_entities)

      # The webhook's own headers first, so they cannot replace the signature
      http_headers = custom_headers(webhook).merge(webhook.signature_headers(http_body.to_s))

      response = HTTParty.send(
        map_webhook_http_method(webhook.http_method).downcase,
        url,
        { body: http_body, headers: http_headers, timeout: TIMEOUT_SECONDS }
      )

      record_delivery(webhook, is_test, started_at, success: response.code.between?(200, 299), http_status: response.code, response_body: response.body)
      response
    rescue Liquid::Error, JSON::ParserError => e
      logger.error do
        "[#{Current.tenant&.subdomain}] Webhook ##{webhook_id} template/JSON error " \
        "(tip: use '| escape_json' on string variables): #{e.class}: #{e.message}"
      end
      record_delivery(webhook, is_test, started_at, error: "#{e.class}: #{e.message} (tip: use the '| escape_json' filter on string variables)")
      raise
    rescue StandardError => e
      record_delivery(webhook, is_test, started_at, error: "#{e.class}: #{e.message}")
      raise
    end
  end

  private

    # URL and JSON body rendered with the trigger's context
    def render_request(webhook, is_test, loaded_entities)
      context = CreateLiquidTemplateContextWorkflow.new(
        webhook_trigger: webhook.trigger,
        is_test: is_test,
        entities: loaded_entities,
      ).run

      url = Liquid::Template.parse(webhook.url).render(context)
      http_body = Liquid::Template.parse(webhook.http_body).render(context)
      http_body = webhook.http_body.present? ? JSON.parse(http_body).to_json : nil

      [url, http_body]
    end

    def custom_headers(webhook)
      return {} if webhook.http_headers.blank?

      rows = webhook.http_headers.is_a?(String) ? JSON.parse(webhook.http_headers) : webhook.http_headers
      rows.each_with_object({}) { |header, memo| memo[header['key']] = header['value'] }
    end

    # Delivery log (#458); never lets a logging problem hide the webhook's own result
    def record_delivery(webhook, is_test, started_at, success: false, http_status: nil, error: nil, response_body: nil)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      WebhookDelivery.record!(
        webhook: webhook, trigger: webhook.trigger, is_test: is_test, success: success,
        duration_ms: duration_ms, http_status: http_status, error: error, response_body: response_body
      )
    rescue StandardError => e
      logger.error { "[webhooks] Could not record delivery of webhook ##{webhook.id}: #{e.class}: #{e.message}" }
    end

    # The enum value is a string ("http_put"); comparing with symbols sent every webhook as POST
    def map_webhook_http_method(http_method)
      case http_method.to_s
      when 'http_put'
        'PUT'
      when 'http_patch'
        'PATCH'
      when 'http_delete'
        'DELETE'
      else # 'http_post'
        'POST'
      end
    end

    def map_entity_name_to_class(entity_name)
      case entity_name
      when :post
        Post
      when :user, :post_author, :comment_author, :vote_author
        User
      when :board
        Board
      when :post_status
        PostStatus
      when :comment
        Comment
      else
        nil
      end
    end
end