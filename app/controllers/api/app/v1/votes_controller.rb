module Api::App::V1
  # The current user's vote on a post (stored as Like). Both actions are idempotent.
  class VotesController < Api::App::BaseController
    before_action :require_access
    before_action :require_user
    before_action :check_tenant_subscription

    # POST /api/app/v1/posts/:post_id/vote
    def create
      post = find_visible_post(params[:post_id])
      Like.find_or_create_by!(post: post, user: current_user)
      render json: vote_state(post)
    end

    # DELETE /api/app/v1/posts/:post_id/vote
    def destroy
      post = find_visible_post(params[:post_id])
      Like.find_by(post: post, user: current_user)&.destroy!
      render json: vote_state(post)
    end

    private

      def vote_state(post)
        { liked: post.likes.exists?(user_id: current_user.id), likesCount: post.likes.count }
      end
  end
end
