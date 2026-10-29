# Shared by all feeds: @title, @description, @link and @posts (newest first)
xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title @title
    xml.link @link
    xml.description @description
    xml.language I18n.locale.to_s
    xml.tag! 'atom:link', href: request.original_url, rel: 'self', type: 'application/rss+xml'
    xml.lastBuildDate((@posts.first&.created_at || Time.current).rfc2822)

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link post_url(post)
        xml.guid post_url(post), isPermaLink: 'true'
        xml.pubDate post.created_at.rfc2822
        xml.category post.post_status.name if post.post_status
        # Markdown source as plain text; feed readers show it as is
        xml.description post.description.to_s
      end
    end
  end
end
