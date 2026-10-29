# RSS 2.0 feeds for feed readers and tools like Slack's RSS app. Public feedback spaces only:
# feed readers cannot sign in, so private spaces have no feeds.
#   GET /boards/:id/feed  newest approved posts of a board
class FeedsController < ApplicationController
  FEED_SIZE = 30

  before_action :require_public_space

  rescue_from(ActiveRecord::RecordNotFound) { head :not_found }

  def board
    @board = Board.friendly.find(params[:id])
    @posts = @board.posts
      .where(approval_status: 'approved')
      .includes(:post_status)
      .order(created_at: :desc)
      .limit(FEED_SIZE)
    @title = "#{@board.name} · #{@tenant.site_name}"
    @description = @board.description.presence || @board.name
    @link = board_url(@board)

    expires_in 10.minutes, public: true
    render :feed, formats: :rss
  end

  private

    def require_public_space
      head :not_found if @tenant.nil? || @tenant_setting.is_private
    end
end
