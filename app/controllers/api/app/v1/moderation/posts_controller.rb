module Api::App::V1::Moderation
  # Feedback queue: posts waiting for approval and rejected posts (legacy: /moderation/feedback).
  # Approve or reject with PATCH /api/app/v1/posts/:id { approvalStatus }.
  class PostsController < Api::App::BaseController
    LIMIT = 100

    before_action :require_moderator

    # GET /api/app/v1/moderation/posts
    def index
      posts = Post
        .includes(:user)
        .where(approval_status: %w[pending rejected])
        .order(created_at: :desc)
        .limit(LIMIT)

      render json: {
        posts: posts.map { |post| Api::App::V1::PostSerializer.moderation_item(post) },
        pendingCount: Post.pending.count,
        allowAnonymousFeedback: tenant_setting.allow_anonymous_feedback,
        feedbackApprovalPolicy: tenant_setting.feedback_approval_policy
      }
    end
  end
end
