class PostStatusChangesController < ApplicationController
  before_action :hide_unless_post_visible, only: [:index]

  def index
    post_status_changes = PostStatusChange
      .select(
        :post_status_id,
        :created_at,
        :user_id,
        'users.full_name as user_full_name',
        'users.email as user_email',
      )
      .where(post_id: params[:post_id])
      .left_outer_joins(:user)
      .order(created_at: :asc)

    render json: post_status_changes.map { |change| Legacy::AuthorFields.merge(change, viewer: current_user) }
  end
end