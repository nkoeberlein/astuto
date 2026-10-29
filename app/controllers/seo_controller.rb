# For search engines (feedback portals live from being found):
#   GET /robots.txt   keeps crawlers out of private spaces and account pages, names the sitemap
#   GET /sitemap.xml  home, roadmap, boards and approved posts of a public feedback space
class SeoController < ApplicationController
  # The sitemap protocol allows 50,000 URLs per file
  MAX_POSTS = 49_000

  def robots
    expires_in 1.hour, public: true
    render plain: robots_txt, content_type: 'text/plain'
  end

  def sitemap
    return head :not_found if @tenant.nil? || @tenant_setting.is_private

    @boards = Board.order(order: :asc).to_a
    @board_updates = Post.where(approval_status: 'approved').group(:board_id).maximum(:updated_at)
    @posts = Post.where(approval_status: 'approved').order(updated_at: :desc).limit(MAX_POSTS).select(:id, :slug, :updated_at)
    @roadmap = @tenant_setting.roadmap_enabled

    expires_in 1.hour, public: true
    render formats: :xml
  end

  private

    def robots_txt
      return "User-agent: *\nDisallow: /\n" if @tenant.nil? || @tenant_setting.is_private

      <<~TXT
        User-agent: *
        Disallow: /api/
        Disallow: /moderation/
        Disallow: /site_settings/
        Disallow: /profile
        Disallow: /my-feedback
        Disallow: /embedded_roadmap

        Sitemap: #{sitemap_url}
      TXT
    end
end
