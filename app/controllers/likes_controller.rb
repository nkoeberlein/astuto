class LikesController < ApplicationController
  before_action :hide_unless_post_visible, only: [:index]
  before_action :authenticate_user!, only: [:create, :destroy]
  before_action :check_tenant_subscription, only: [:create, :destroy]

  def index
    likes = Like
      .select(
        :id,
        :user_id,
        :full_name,
        :email
      )
      .left_outer_joins(:user)
      .where(post_id: params[:post_id])

    render json: likes.map { |like| Legacy::AuthorFields.merge(like, viewer: current_user, email_attribute: :email, prefix: '') }
  end

  def create
    like = Like.new(like_params)

    if like.save
      render json: {
        id: like.id,
        user_id: current_user.id,
        full_name: current_user.full_name,
      }.merge(Legacy::AuthorFields.call(viewer: current_user, user_id: current_user.id, email: current_user.email, prefix: '')), status: :created
    else
      render json: {
        error: like.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    like = Like.find_by(like_params)
    id = like.id
    
    return if like.nil?

    if like.destroy
      render json: {
        id: id,
      }, status: :accepted
    else
      render json: {
        error: like.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

    def like_params
      {
        post_id: params[:post_id],
        user_id: current_user.id,
      }
    end
end
