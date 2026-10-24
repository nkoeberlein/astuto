module Api::App::V1
  class CommentsController < Api::App::BaseController
    before_action :require_access
    before_action :require_user, only: [:create]
    before_action :check_tenant_subscription, only: [:create]

    # GET /api/app/v1/posts/:post_id/comments
    def index
      post = find_visible_post(params[:post_id])
      comments = post.comments.includes(:user).order(created_at: :asc)
      render json: comments.map { |comment| CommentSerializer.call(comment) }
    end

    # POST /api/app/v1/posts/:post_id/comments { body, parentId, isPostUpdate }
    def create
      post = find_visible_post(params[:post_id])
      parent = params[:parentId].present? ? post.comments.find(params[:parentId]) : nil

      comment = Comment.new(
        post: post,
        user: current_user,
        parent: parent,
        body: params[:body],
        # Only moderators can mark a comment as an official post update
        is_post_update: current_user.moderator? && ActiveModel::Type::Boolean.new.cast(params[:isPostUpdate]) || false
      )
      return render_error(:unprocessable_content, comment.errors.full_messages.join(', ')) unless comment.save

      SendNotificationForCommentWorkflow.new(comment: comment).run
      render status: :created, json: CommentSerializer.call(comment)
    end
  end
end
