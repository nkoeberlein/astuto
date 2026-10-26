module Api::App::V1
  class PostsController < Api::App::BaseController
    before_action :require_access
    before_action :require_user, only: [:update, :destroy]
    before_action :check_tenant_subscription, only: [:create, :update, :destroy]

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
    # { title, description, isAnonymous, honeypot, formFillMs }
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
        approval_status: tenant_setting.approval_status_for_new_post(user: current_user, anonymous: anonymous),
        post_status_id: post_status_id
      )

      saved = CreatePostWorkflow.new(
        post: post,
        follower: anonymous ? nil : current_user,
        status_actor: current_user
      ).run
      return render_error(:unprocessable_content, post.errors.full_messages.join(', ')) unless saved
      render status: :created, json: PostSerializer.detail(post, current_user: current_user)
    end

    # PATCH /api/app/v1/posts/:id
    # { title, description, boardId, postStatusId, approvalStatus }
    def update
      post = find_visible_post(params[:id])
      authorize post, :update?

      post.title = params[:title] if params.key?(:title)
      post.description = params[:description] if params.key?(:description)

      if current_user.moderator?
        if params.key?(:boardId) && params[:boardId].present?
          board = Board.find_by(id: params[:boardId].to_i)
          return render_error(:unprocessable_content, I18n.t('errors.unknown')) if board.nil?

          post.board = board
        end

        if params.key?(:postStatusId)
          if params[:postStatusId].nil?
            post.post_status_id = nil
          else
            status = Current.tenant.post_statuses.find_by(id: params[:postStatusId].to_i)
            return render_error(:unprocessable_content, I18n.t('errors.unknown')) if status.nil?

            post.post_status_id = status.id
          end
        end

        if params.key?(:approvalStatus) && params[:approvalStatus].present?
          # Assigning an unknown enum value raises ArgumentError (500)
          unless Post.approval_statuses.key?(params[:approvalStatus].to_s)
            return render_error(:unprocessable_content, I18n.t('errors.unknown'))
          end

          post.approval_status = params[:approvalStatus]
        end
      end

      status_changed = post.post_status_id_changed?
      status_change_workflow = ExecutePostStatusChangeLogicWorkflow.new(
        user_id: current_user.id,
        post: post,
        post_status_id: post.post_status_id
      )

      saved = ActiveRecord::Base.transaction do
        result = post.save
        status_change_workflow.create_status_change! if result && status_changed
        result
      end
      return render_error(:unprocessable_content, post.errors.full_messages.join(', ')) unless saved

      status_change_workflow.notify_followers if status_changed
      render json: PostSerializer.detail(post, current_user: current_user)
    end

    # DELETE /api/app/v1/posts/:id
    def destroy
      post = find_visible_post(params[:id])
      authorize post, :destroy?

      post.destroy!
      head :no_content
    end

    private

      # Honeypot field must stay empty and the form must have been open for a moment
      def spam?
        PostSpamCheck.honeypot_filled?(params[:honeypot]) || PostSpamCheck.too_fast?(params[:formFillMs])
      end
  end
end
