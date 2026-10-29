module Api::App::V1
  class BoardsController < Api::App::BaseController
    before_action :require_access, only: [:index, :show]
    before_action :require_admin, except: [:index, :show]

    # GET /api/app/v1/boards
    def index
      render json: Board.order(order: :asc).map { |board| BoardSerializer.call(board) }
    end

    # GET /api/app/v1/boards/:id (id or slug)
    def show
      render json: BoardSerializer.call(Board.friendly.find(params[:id]))
    end

    # POST /api/app/v1/boards { name, description, slug } (admins)
    def create
      board = Board.new(board_params)
      return render_error(:unprocessable_content, board.errors.full_messages.join(', ')) unless board.save

      audit('board.create', board, changes: board.saved_changes)
      render status: :created, json: BoardSerializer.call(board)
    end

    # PATCH /api/app/v1/boards/:id { name, description, slug } (admins)
    def update
      board = Board.find(params[:id])
      return render_error(:unprocessable_content, board.errors.full_messages.join(', ')) unless board.update(board_params)

      audit('board.update', board, changes: board.saved_changes) if board.saved_changes?
      render json: BoardSerializer.call(board)
    end

    # DELETE /api/app/v1/boards/:id (admins). Deletes the board's posts as well.
    def destroy
      board = Board.find(params[:id])
      board.destroy!
      audit('board.delete', board)
      head :no_content
    end

    # PUT /api/app/v1/boards/reorder { ids: [...] } (admins): all board ids in the new order
    def reorder
      return render_error(:unprocessable_content, I18n.t('errors.board.update_order')) unless apply_order(Board, params[:ids])

      audit('board.reorder')
      index
    end

    private

      def board_params
        params.slice(:name, :description, :slug).permit(:name, :description, :slug).to_h.tap do |attributes|
          # A blank slug lets friendly_id generate one from the name
          attributes['slug'] = nil if attributes.key?('slug') && attributes['slug'].blank?
        end
      end
  end
end
