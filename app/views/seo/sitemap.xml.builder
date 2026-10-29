xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.urlset xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  xml.url { xml.loc root_url }
  xml.url { xml.loc roadmap_url } if @roadmap

  @boards.each do |board|
    xml.url do
      xml.loc board_url(board)
      xml.lastmod @board_updates[board.id].iso8601 if @board_updates[board.id]
    end
  end

  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.updated_at.iso8601
    end
  end
end
