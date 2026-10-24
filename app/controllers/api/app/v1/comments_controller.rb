module Api::App::V1
  class CommentsController < Api::App::BaseController
    before_action :require_access

    # GET /api/app/v1/posts/:post_id/comments
    def index
      post = Post.friendly.find(params[:post_id])
      raise ActiveRecord::RecordNotFound unless post.approved? || current_user&.moderator?

      comments = post.comments.includes(:user).order(created_at: :asc)
      render json: comments.map { |comment| CommentSerializer.call(comment) }
    end
  end
end
