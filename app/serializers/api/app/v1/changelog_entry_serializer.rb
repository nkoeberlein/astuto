module Api::App::V1
  # Changelog entry with the posts it delivers (only approved ones are shown)
  module ChangelogEntrySerializer
    def self.call(entry)
      {
        id: entry.id,
        title: entry.title,
        body: entry.body,
        publishedAt: entry.published_at&.iso8601,
        posts: entry.posts.select(&:approved?).sort_by(&:title).map { |post| { id: post.id, title: post.title, slug: post.slug } }
      }
    end
  end
end
