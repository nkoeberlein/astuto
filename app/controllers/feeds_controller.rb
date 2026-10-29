# RSS 2.0 feeds for feed readers and tools like Slack's RSS app. Public feedback spaces only:
# feed readers cannot sign in, so private spaces have no feeds.
#   GET /boards/:id/feed  newest approved posts of a board
#   GET /changelog/feed   published changelog entries
class FeedsController < ApplicationController
  FEED_SIZE = 30

  Item = Struct.new(:title, :link, :published_at, :category, :description, keyword_init: true)

  before_action :require_public_space

  rescue_from(ActiveRecord::RecordNotFound) { head :not_found }

  def board
    board = Board.visible_to_everyone.friendly.find(params[:id])
    posts = board.posts
      .where(approval_status: 'approved')
      .includes(:post_status)
      .order(created_at: :desc)
      .limit(FEED_SIZE)
    # Markdown source as plain text; feed readers show it as is
    items = posts.map do |post|
      Item.new(title: post.title, link: post_url(post), published_at: post.created_at,
               category: post.post_status&.name, description: post.description.to_s)
    end
    render_feed(title: "#{board.name} · #{@tenant.site_name}", description: board.description.presence || board.name,
                link: board_url(board), items: items)
  end

  def changelog
    entries = ChangelogEntry.published.newest_first.limit(FEED_SIZE)
    items = entries.map do |entry|
      Item.new(title: entry.title, link: changelog_url(anchor: "entry-#{entry.id}"), published_at: entry.published_at,
               description: entry.body)
    end
    title = "#{I18n.t('changelog.title')} · #{@tenant.site_name}"
    render_feed(title: title, description: title, link: changelog_url, items: items)
  end

  private

    def require_public_space
      head :not_found if @tenant.nil? || @tenant_setting.is_private
    end

    def render_feed(title:, description:, link:, items:)
      @title = title
      @description = description
      @link = link
      @items = items
      expires_in 10.minutes, public: true
      render :feed, formats: :rss
    end
end
