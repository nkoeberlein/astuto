module Api::App::V1
  # AI suggestion of board and tags for a post, for moderators. The model may only pick from
  # the existing boards and tags; anything else is dropped. Nothing is changed: the moderator
  # applies the suggestion. Only with an AI provider (see Ai::Client and docs/mcp-and-ai.md).
  class SuggestionsController < Api::App::BaseController
    CACHE_TTL = 1.day

    before_action :require_access
    before_action :require_user

    # POST /api/app/v1/posts/:post_id/suggestion
    def create
      post = find_visible_post(params[:post_id])
      authorize post, :summarize?

      client = Ai::Client.from_env
      return render_error(:not_found, 'AI features are not enabled') unless client.enabled?

      boards = Board.order(order: :asc).to_a
      tags = Tag.order(order: :asc).to_a
      answer = Rails.cache.fetch(cache_key(post, client, boards, tags), expires_in: CACHE_TTL) do
        client.suggest_board_and_tags(title: post.title, description: post.description, boards: boards, tags: tags)
      end

      by_name = ->(records, name) { records.find { |record| record.name.casecmp?(name.to_s.strip) } }
      render json: {
        boardId: by_name.call(boards, answer['board'])&.id,
        tagIds: answer['tags'].filter_map { |name| by_name.call(tags, name)&.id }.uniq
      }
    rescue Ai::Client::ProviderError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.warn("[AI] Suggestion for post #{post&.id} failed: #{e.class}: #{e.message}")
      render_error(:bad_gateway, I18n.t('errors.unknown'))
    end

    private

      def cache_key(post, client, boards, tags)
        [
          'ai-suggestion', Current.tenant.id, post.id, post.updated_at.to_i, client.provider, client.model,
          boards.map { |b| [b.id, b.updated_at.to_i] }, tags.map { |t| [t.id, t.updated_at.to_i] }
        ]
      end
  end
end
