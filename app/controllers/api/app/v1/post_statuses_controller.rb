module Api::App::V1
  class PostStatusesController < Api::App::BaseController
    before_action :require_access

    # GET /api/app/v1/post_statuses
    def index
      render json: PostStatus.order(order: :asc).map { |status| PostStatusSerializer.call(status) }
    end
  end
end
