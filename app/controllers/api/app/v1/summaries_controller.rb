module Api::App::V1
  # AI summary of a post and its discussion, for moderators. Only available when an
  # AI provider is configured (see Ai::Client and docs/mcp-and-ai.md).
  class SummariesController < Api::App::BaseController
    CACHE_TTL = 1.day

    before_action :require_access
    before_action :require_user

    # POST /api/app/v1/posts/:post_id/summary
    def create
      post = find_visible_post(params[:post_id])
      authorize post, :summarize?

      client = Ai::Client.from_env
      return render_error(:not_found, 'AI features are not enabled') unless client.enabled?

      # Same post text and comments give the same summary, so repeat clicks cost nothing
      summary = Rails.cache.fetch(cache_key(post, client), expires_in: CACHE_TTL) do
        client.summarize_discussion(post: post, locale: I18n.locale)
      end
      render json: { summary: summary }
    rescue Ai::Client::ProviderError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.warn("[AI] Summary for post #{post&.id} failed: #{e.class}: #{e.message}")
      render_error(:bad_gateway, I18n.t('errors.unknown'))
    end

    private

      def cache_key(post, client)
        comments = post.comments
        [
          'ai-summary', Current.tenant.id, post.id, post.updated_at.to_i,
          comments.count, comments.maximum(:updated_at).to_i,
          client.provider, client.model, I18n.locale
        ]
      end
  end
end
