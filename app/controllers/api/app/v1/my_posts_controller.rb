module Api::App::V1
  # "My feedback": posts the signed-in person created, voted on or follows (#429)
  class MyPostsController < Api::App::BaseController
    before_action :require_user

    # GET /api/app/v1/my_posts?filter=created|voted|followed&page=1
    def index
      query = MyPostsQuery.new(user: current_user, filter: params[:filter], page: params[:page] || 1)
      result = query.call
      boards = Board.where(id: result.posts.map(&:board_id)).index_by(&:id)

      render json: {
        filter: query.filter,
        counts: query.counts,
        posts: result.posts.map { |post| PostSerializer.my_item(post, board: boards[post.board_id]) },
        page: result.page,
        hasMore: result.has_more
      }
    end
  end
end
