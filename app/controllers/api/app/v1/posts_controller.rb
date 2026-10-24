module Api::App::V1
  class PostsController < Api::App::BaseController
    MIN_SECONDS_TO_FILL_FORM = 2

    before_action :require_access
    before_action :check_tenant_subscription, only: [:create]

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
      render json: PostSerializer.detail(find_visible_post(params[:id]), current_user: current_user)
    end

    # POST /api/app/v1/boards/:board_id/posts
    # { title, description, isAnonymous, honeypot, formRenderedAt }
    def create
      board = Board.friendly.find(params[:board_id])
      anonymous = ActiveModel::Type::Boolean.new.cast(params[:isAnonymous]) || false

      return render_error(:unprocessable_content, I18n.t('errors.unknown')) if spam?
      return render_error(:unauthorized, I18n.t('errors.not_logged_in')) if !anonymous && !user_signed_in?
      return render_error(:forbidden, I18n.t('errors.unauthorized')) if anonymous && !tenant_setting.allow_anonymous_feedback

      # Moderators may pick an initial status for the post (#119)
      post_status_id = nil
      if current_user&.moderator? && params[:postStatusId].present?
        status = Current.tenant.post_statuses.find_by(id: params[:postStatusId].to_i)
        return render_error(:unprocessable_content, I18n.t('errors.unknown')) if status.nil?
        post_status_id = status.id
      end

      post = Post.new(
        board: board,
        title: params[:title],
        description: params[:description],
        user: anonymous ? nil : current_user,
        approval_status: approval_status_for(anonymous: anonymous),
        post_status_id: post_status_id
      )

      # The post creation and the author's follow must both happen or neither (#169)
      saved = ActiveRecord::Base.transaction do
        result = post.save
        Follow.create(post: post, user: current_user) if result && !anonymous
        # A moderator-chosen initial status belongs to the timeline
        PostStatusChange.create(user_id: current_user.id, post_id: post.id, post_status_id: post_status_id) if result && post_status_id.present?
        result
      end
      return render_error(:unprocessable_content, post.errors.full_messages.join(', ')) unless saved
      render status: :created, json: PostSerializer.detail(post, current_user: current_user)
    end

    private

      # Honeypot field must stay empty and the form must have been open for a moment
      def spam?
        rendered_at = params[:formRenderedAt].to_i
        params[:honeypot].present? || rendered_at.zero? || Time.now.to_i - rendered_at < MIN_SECONDS_TO_FILL_FORM
      end

      # Same rules as the legacy UI (TenantSetting#feedback_approval_policy)
      def approval_status_for(anonymous:)
        return 'approved' if current_user&.moderator?

        case tenant_setting.feedback_approval_policy
        when 'never_require_approval' then 'approved'
        when 'anonymous_require_approval' then anonymous ? 'pending' : 'approved'
        else 'pending'
        end
      end
  end
end
