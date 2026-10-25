module Api::App::V1
  class BoardsController < Api::App::BaseController
    before_action :require_access

    # GET /api/app/v1/boards
    def index
      render json: Board.order(order: :asc).map { |board| BoardSerializer.call(board) }
    end

    # GET /api/app/v1/boards/:id (id or slug)
    def show
      render json: BoardSerializer.call(Board.friendly.find(params[:id]))
    end
  end
end
