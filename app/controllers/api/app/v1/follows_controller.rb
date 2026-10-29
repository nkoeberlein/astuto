module Api::App::V1
  # Whether the current user receives notifications about a post. Both actions are idempotent.
  class FollowsController < Api::App::BaseController
    before_action :require_access
    before_action :require_user

    # POST /api/app/v1/posts/:post_id/follow
    def create
      post = find_visible_post(params[:post_id])
      Follow.find_or_create_by!(post: post, user: current_user)
      render json: { followed: true }
    end

    # DELETE /api/app/v1/posts/:post_id/follow
    def destroy
      post = find_visible_post(params[:post_id])
      Follow.find_by(post: post, user: current_user)&.destroy!
      render json: { followed: false }
    end
  end
end
