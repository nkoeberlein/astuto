# frozen_string_literal: true

module Mcp
  module Tools
    class MergePosts < Base
      tool_name 'merge_posts'
      description 'Merge a duplicate post into another one: votes, followers and comments move to the target, ' \
                  'the duplicate redirects there. Not reversible; check both posts with get_post first.'
      input_schema(
        properties: {
          duplicate_post_id: { type: 'integer', description: 'ID of the duplicate that disappears.' },
          target_post_id: { type: 'integer', description: 'ID of the post that stays and takes over votes and comments.' }
        },
        required: %w[duplicate_post_id target_post_id],
        additionalProperties: false
      )
      annotations(read_only_hint: false, destructive_hint: true, idempotent_hint: false, open_world_hint: false)

      def self.run(user:, duplicate_post_id:, target_post_id:)
        source = Post.find(duplicate_post_id)
        target = Post.find(target_post_id)
        MergePostsWorkflow.new(source: source, target: target, actor: user).run!
        audit('post.merge', user, source, { 'merged_into_post_id' => [nil, target.id] })

        {
          merged: { duplicate_post_id: source.id, target_post_id: target.id },
          target: { id: target.id, slug: target.slug, title: target.title, likes_count: target.likes.count, comments_count: target.comments.count }
        }
      rescue MergePostsWorkflow::Error => e
        raise ArgumentError, e.message
      end
    end
  end
end
