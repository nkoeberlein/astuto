class PostsController < ApplicationController
  before_action :authenticate_user!, only: [:update, :destroy]
  before_action :authenticate_moderator, only: [:moderation]
  before_action :check_tenant_subscription, only: [:create, :update, :destroy]

  def index
    start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.parse('1970-01-01')
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

    posts = Post
      .select(
        :id,
        :title,
        :slug,
        :description,
        :post_status_id,
        'COUNT(DISTINCT likes.id) AS likes_count',
        'COUNT(DISTINCT comments.id) AS comments_count',
        '((LOG(COUNT(DISTINCT likes.id) + 1) + LOG(COUNT(DISTINCT comments.id) + 1)) + (EXTRACT(EPOCH FROM posts.created_at) / 45000)) AS hotness',
        "(SELECT COUNT(*) AS liked FROM likes WHERE likes.user_id=#{current_user ? current_user.id : -1} AND likes.post_id=posts.id)"
      )
      .left_outer_joins(:likes)
      .left_outer_joins(:comments)
      .group('posts.id')
      .where(board_id: params[:board_id] || Board.first.id)
      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .where(approval_status: "approved")
      .search_by_name_or_description(params[:search])
      .order_by(params[:sort_by])
      .page(params[:page])

    # apply post status filter if present
    posts = posts.where(post_status_id: params[:post_status_ids].map { |id| id == "0" ? nil : id }) if params[:post_status_ids].present?
    
    render json: posts
  end

  def create
    if anti_spam_checks || invalid_anonymous_submission
      render json: {
        error: t('errors.unknown')
      }, status: :unprocessable_entity
      return
    end

    is_anonymous = anonymous_submission?
    approval_status = Current.tenant.tenant_setting.approval_status_for_new_post(
      user: current_user,
      anonymous: is_anonymous
    )

    @post = Post.new(approval_status: approval_status)
    @post.assign_attributes(post_create_params(is_anonymous: is_anonymous))

    saved = CreatePostWorkflow.new(post: @post, follower: is_anonymous ? nil : current_user).run

    if saved
      render json: @post, status: :created
    else
      render json: {
        error: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])
    authorize @post
    
    @post.assign_attributes(post_update_params)
    status_changed = @post.post_status_id_changed?

    status_change_workflow = ExecutePostStatusChangeLogicWorkflow.new(
      user_id: current_user.id,
      post: @post,
      post_status_id: @post.post_status_id
    )

    # The post update and its status change record must both happen or neither (#169)
    saved = ActiveRecord::Base.transaction do
      result = @post.save
      status_change_workflow.create_status_change! if result && status_changed
      result
    end

    # Mails are enqueued after the transaction has committed
    status_change_workflow.notify_followers if saved && status_changed

    if saved
      render json: @post
    else
      render json: {
        error: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @post = Post.find(params[:id])
    authorize @post

    if @post.destroy
      render json: {
        id: @post.id,
      }, status: :accepted
    else
      render json: {
        error: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Returns a list of posts for moderation in JSON
  def moderation
    posts = Post
      .select(
        :id,
        :title,
        :description,
        :slug,
        :approval_status,
        :user_id,
        :board_id,
        :created_at,
        'users.email as user_email',
        'users.full_name as user_full_name'
      )
      .eager_load(:user)
      .where(approval_status: ["pending", "rejected"])
      .order_by(created_at: :desc)
      .limit(100)

    render json: posts
  end

  private


    def anti_spam_checks
      rendered_at = params[:post][:form_rendered_at].to_i
      params[:post][:dnf1] != "" || params[:post][:dnf2] != "" || rendered_at.zero? || Time.now.to_i - rendered_at < 2
    end

    def anonymous_submission?
      ActiveModel::Type::Boolean.new.cast(params[:post][:is_anonymous]) || false
    end

    def invalid_anonymous_submission
      (!anonymous_submission? && !user_signed_in?) ||
        (anonymous_submission? && !Current.tenant.tenant_setting.allow_anonymous_feedback)
    end
    
    def post_create_params(is_anonymous: false)
      params
        .require(:post)
        .permit(policy(@post).permitted_attributes_for_create)
        .merge(user_id: is_anonymous ? nil : current_user.id)
    end

    def post_update_params
      params
        .require(:post)
        .permit(policy(@post).permitted_attributes_for_update)
    end
end
