# Shared by all feeds (FeedsController): @title, @description, @link, @items (newest first)
xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title @title
    xml.link @link
    xml.description @description
    xml.language I18n.locale.to_s
    xml.tag! 'atom:link', href: request.original_url, rel: 'self', type: 'application/rss+xml'
    xml.lastBuildDate((@items.first&.published_at || Time.current).rfc2822)

    @items.each do |item|
      xml.item do
        xml.title item.title
        xml.link item.link
        xml.guid item.link, isPermaLink: 'true'
        xml.pubDate item.published_at.rfc2822
        xml.category item.category if item.category
        xml.description item.description
      end
    end
  end
end
