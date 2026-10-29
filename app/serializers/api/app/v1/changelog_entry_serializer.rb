module Api::App::V1
  # Changelog entry with the posts it delivers (only approved ones are shown)
  module ChangelogEntrySerializer
    # viewer: posts on boards they may not see are left out (private boards)
    def self.call(entry, viewer: nil)
      {
        id: entry.id,
        title: entry.title,
        body: entry.body,
        publishedAt: entry.published_at&.iso8601,
        posts: entry.posts.select { |post| post.approved? && post.board.visible_to?(viewer) }.sort_by(&:title).map { |post| { id: post.id, title: post.title, slug: post.slug } }
      }
    end
  end
end
