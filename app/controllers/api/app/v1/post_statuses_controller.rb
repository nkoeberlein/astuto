module Api::App::V1
  class PostStatusesController < Api::App::BaseController
    before_action :require_access

    # GET /api/app/v1/post_statuses?board_id=
    def index
      statuses = PostStatus.order(order: :asc)
      if params[:board_id].present? && tenant_setting.hide_unused_statuses_in_filter_by_status
        board = Board.friendly.find(params[:board_id])
        used_ids = board.posts.where(approval_status: 'approved').where.not(post_status_id: nil).distinct.pluck(:post_status_id)
        statuses = statuses.where(id: used_ids)
      end
      render json: statuses.map { |status| PostStatusSerializer.call(status) }
    end
  end
end
