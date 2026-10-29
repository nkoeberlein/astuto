module Api::App::V1
  class PostStatusesController < Api::App::BaseController
    before_action :require_access, only: [:index]
    before_action :require_admin, except: [:index]
    before_action :check_tenant_subscription, except: [:index]

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

    # POST /api/app/v1/post_statuses { name, color, showInRoadmap } (admins)
    def create
      status = PostStatus.new(status_params)
      return render_error(:unprocessable_content, status.errors.full_messages.join(', ')) unless status.save

      render status: :created, json: PostStatusSerializer.call(status)
    end

    # PATCH /api/app/v1/post_statuses/:id { name, color, showInRoadmap } (admins)
    def update
      status = PostStatus.find(params[:id])
      return render_error(:unprocessable_content, status.errors.full_messages.join(', ')) unless status.update(status_params)

      render json: PostStatusSerializer.call(status)
    end

    # DELETE /api/app/v1/post_statuses/:id (admins). Posts keep existing without a status.
    def destroy
      PostStatus.find(params[:id]).destroy!
      head :no_content
    end

    # PUT /api/app/v1/post_statuses/reorder { ids: [...] } (admins): all status ids in the new order
    def reorder
      return render_error(:unprocessable_content, I18n.t('errors.post_status.update_order')) unless apply_order(PostStatus, params[:ids])

      render json: PostStatus.order(order: :asc).map { |status| PostStatusSerializer.call(status) }
    end

    private

      def status_params
        attributes = params.slice(:name, :color).permit(:name, :color).to_h
        attributes['show_in_roadmap'] = params[:showInRoadmap] if params.key?(:showInRoadmap)
        attributes
      end
  end
end
