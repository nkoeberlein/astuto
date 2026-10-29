module Api::App::V1
  # Tags (#171): everyone lists them, admins manage them in Site settings › Tags
  class TagsController < Api::App::BaseController
    before_action :require_access, only: [:index]
    before_action :require_admin, except: [:index]

    # GET /api/app/v1/tags
    def index
      render json: Tag.order(order: :asc).map { |tag| TagSerializer.call(tag) }
    end

    # POST /api/app/v1/tags { name, color }
    def create
      tag = Tag.new(tag_params)
      return render_error(:unprocessable_content, tag.errors.full_messages.join(', ')) unless tag.save

      audit('tag.create', tag, changes: tag.saved_changes)
      render status: :created, json: TagSerializer.call(tag)
    end

    # PATCH /api/app/v1/tags/:id { name, color }
    def update
      tag = Tag.find(params[:id])
      return render_error(:unprocessable_content, tag.errors.full_messages.join(', ')) unless tag.update(tag_params)

      audit('tag.update', tag, changes: tag.saved_changes) if tag.saved_changes?
      render json: TagSerializer.call(tag)
    end

    # DELETE /api/app/v1/tags/:id : the tag goes away from all posts
    def destroy
      tag = Tag.find(params[:id])
      tag.destroy!
      audit('tag.delete', tag)
      head :no_content
    end

    # PUT /api/app/v1/tags/reorder { ids: [...] }
    def reorder
      return render_error(:unprocessable_content, I18n.t('errors.unknown')) unless apply_order(Tag, params[:ids])

      audit('tag.reorder')
      render json: Tag.order(order: :asc).map { |tag| TagSerializer.call(tag) }
    end

    private

      def tag_params
        params.slice(:name, :color).permit(:name, :color)
      end
  end
end
