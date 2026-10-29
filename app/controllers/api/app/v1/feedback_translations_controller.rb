module Api::App::V1
  # AI translation of a post or comment into the language of the interface, for moderators.
  # Only available when an AI provider is configured (see Ai::Client and docs/mcp-and-ai.md).
  # Nothing is stored: the translation is shown next to the original and cached for a week.
  class FeedbackTranslationsController < Api::App::BaseController
    CACHE_TTL = 7.days

    before_action :require_access
    before_action :require_user
    before_action :load_post_and_client

    rescue_from Ai::Client::ProviderError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED do |e|
      Rails.logger.warn("[AI] Translation for post #{@post&.id} failed: #{e.class}: #{e.message}")
      render_error(:bad_gateway, I18n.t('errors.unknown'))
    end

    # POST /api/app/v1/posts/:post_id/translation
    def translate_post
      render json: {
        title: translate(@post.title),
        description: @post.description.present? ? translate(@post.description) : nil,
        locale: I18n.locale.to_s
      }
    end

    # POST /api/app/v1/posts/:post_id/comments/:comment_id/translation
    def translate_comment
      comment = @post.comments.find(params[:comment_id])
      render json: { body: translate(comment.body), locale: I18n.locale.to_s }
    end

    private

      def load_post_and_client
        @post = find_visible_post(params[:post_id])
        authorize @post, :translate?

        @client = Ai::Client.from_env
        render_error(:not_found, 'AI features are not enabled') unless @client.enabled?
      end

      # The same text in the same language gives the same translation, so it is cached by content
      def translate(text)
        key = [
          'ai-translation', Current.tenant.id, @client.provider, @client.model, I18n.locale,
          Digest::SHA256.hexdigest(text.to_s)
        ]
        Rails.cache.fetch(key, expires_in: CACHE_TTL) do
          translation = @client.translate_feedback(text: text, target_locale: I18n.locale)
          # An empty answer is a failed call, not a translation (and must not be cached)
          raise Ai::Client::ProviderError, 'empty translation' if translation.blank?

          translation
        end
      end
  end
end
