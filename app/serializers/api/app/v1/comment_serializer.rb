module Api::App::V1
  module CommentSerializer
    def self.call(comment)
      {
        id: comment.id,
        body: comment.body,
        parentId: comment.parent_id,
        isPostUpdate: comment.is_post_update,
        author: AuthorSerializer.call(comment.user),
        createdAt: comment.created_at.iso8601,
        updatedAt: comment.updated_at.iso8601
      }
    end
  end
end
