module Api::App::V1
  class RoadmapsController < Api::App::BaseController
    before_action :require_access

    # GET /api/app/v1/roadmap?sort_by=most_voted|recently_updated
    def show
      return render_not_found unless tenant_setting.roadmap_enabled

      columns = RoadmapQuery.new(user: current_user, sort_by: params[:sort_by]).call

      render json: {
        columns: columns.map do |column|
          {
            status: PostStatusSerializer.call(column.status),
            postsCount: column.posts_count,
            posts: column.posts.map { |post| PostSerializer.roadmap_item(post) }
          }
        end
      }
    end
  end
end
