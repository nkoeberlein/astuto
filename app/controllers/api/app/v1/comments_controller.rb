module Api::App::V1
  class CommentsController < Api::App::BaseController
    before_action :require_access
    before_action :require_user, only: [:create, :update, :destroy]

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

    # PATCH /api/app/v1/posts/:post_id/comments/:id { body, isPostUpdate }
    def update
      post = find_visible_post(params[:post_id])
      comment = post.comments.find(params[:id])
      authorize comment, :update?

      comment.body = params[:body] if params.key?(:body)
      if current_user.moderator? && params.key?(:isPostUpdate)
        comment.is_post_update = ActiveModel::Type::Boolean.new.cast(params[:isPostUpdate]) || false
      end

      return render_error(:unprocessable_content, comment.errors.full_messages.join(', ')) unless comment.save

      render json: CommentSerializer.call(comment)
    end

    # DELETE /api/app/v1/posts/:post_id/comments/:id
    def destroy
      post = find_visible_post(params[:post_id])
      comment = post.comments.find(params[:id])
      authorize comment, :destroy?

      comment.destroy!
      head :no_content
    end
  end
end
