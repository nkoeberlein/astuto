module Api::App::V1
  class PostsController < Api::App::BaseController
    before_action :require_access

    # GET /api/app/v1/boards/:board_id/posts?search=&sort_by=&post_status_ids[]=&page=
    def index
      board = Board.friendly.find(params[:board_id])
      result = BoardPostsQuery.new(
        board: board,
        user: current_user,
        search: params[:search],
        sort_by: params[:sort_by],
        post_status_ids: params[:post_status_ids],
        page: params[:page] || 1
      ).call

      render json: {
        posts: result.posts.map { |post| PostSerializer.list_item(post) },
        page: result.page,
        hasMore: result.has_more
      }
    end

    # GET /api/app/v1/posts/:id (id or slug)
    def show
      render json: PostSerializer.detail(visible_post, current_user: current_user)
    end

    private

      # Posts that are not approved are only visible to moderators
      def visible_post
        post = Post.friendly.find(params[:id])
        raise ActiveRecord::RecordNotFound unless post.approved? || current_user&.moderator?

        post
      end
  end
end
