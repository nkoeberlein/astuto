# Schemas of the app API (/api/app/v1) used by the v2 frontend.
# Strict on purpose (additionalProperties: false): the generated TypeScript
# types in frontend/src/api/schema.d.ts are built from these.
module Swagger
  module AppSchemas
    def self.object(properties, required: properties.keys, nullable: false)
      { type: :object, properties: properties, required: required.map(&:to_s), additionalProperties: false, nullable: nullable }.compact
    end

    def self.ref(name) = { '$ref' => "#/components/schemas/#{name}" }

    STRING = { type: :string }.freeze
    NULLABLE_STRING = { type: :string, nullable: true }.freeze
    INTEGER = { type: :integer }.freeze
    NULLABLE_INTEGER = { type: :integer, nullable: true }.freeze
    BOOLEAN = { type: :boolean }.freeze
    DATETIME = { type: :string, format: 'date-time' }.freeze

    def self.all
      {
        Error: object({ error: STRING }),
        Author: object({ id: INTEGER, fullName: STRING, avatarUrl: STRING }),
        CurrentUser: object({ id: INTEGER, email: STRING, fullName: STRING, role: { type: :string, enum: %w[user moderator admin owner] }, avatarUrl: STRING }),
        TenantSettings: object({
          brandDisplay: { type: :string, enum: %w[name_and_logo name_only logo_only no_name_no_logo] },
          logoLinksTo: { type: :string, enum: %w[root_page custom_url nothing] }, logoCustomUrl: NULLABLE_STRING, rootBoardId: NULLABLE_INTEGER,
          showRoadmapInHeader: BOOLEAN, showVoteCount: BOOLEAN, showVoteButtonInBoard: BOOLEAN, showPoweredBy: BOOLEAN,
          allowAnonymousFeedback: BOOLEAN, isPrivate: BOOLEAN, hideUnusedStatusesInFilterByStatus: BOOLEAN, customCss: NULLABLE_STRING
        }),
        Tenant: object({ siteName: STRING, siteLogo: NULLABLE_STRING, locale: STRING, settings: ref(:TenantSettings) }),
        Session: object({ csrfToken: STRING, user: ref(:CurrentUser).merge(nullable: true), tenant: ref(:Tenant) }),
        Board: object({ id: INTEGER, name: STRING, slug: STRING, description: NULLABLE_STRING }),
        PostStatus: object({ id: INTEGER, name: STRING, color: STRING, order: INTEGER, showInRoadmap: BOOLEAN }),
        PostListItem: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, postStatusId: NULLABLE_INTEGER,
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, createdAt: DATETIME
        }),
        PostPage: object({ posts: { type: :array, items: ref(:PostListItem) }, page: INTEGER, hasMore: BOOLEAN }),
        Post: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, boardId: INTEGER, postStatusId: NULLABLE_INTEGER,
          approvalStatus: { type: :string, enum: %w[approved pending rejected] }, author: ref(:Author).merge(nullable: true),
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, followed: BOOLEAN, createdAt: DATETIME, updatedAt: DATETIME
        }),
        VoteState: object({ liked: BOOLEAN, likesCount: INTEGER }),
        FollowState: object({ followed: BOOLEAN }),
        NewPost: object({
          title: STRING, description: NULLABLE_STRING, isAnonymous: BOOLEAN,
          honeypot: { type: :string, description: 'Hidden form field, must stay empty' },
          formRenderedAt: { type: :integer, description: 'Unix time when the form was shown (anti-spam)' }
        }, required: %i[title formRenderedAt]),
        NewComment: object({ body: STRING, parentId: NULLABLE_INTEGER, isPostUpdate: BOOLEAN }, required: %i[body]),
        Comment: object({
          id: INTEGER, body: STRING, parentId: NULLABLE_INTEGER, isPostUpdate: BOOLEAN,
          author: ref(:Author).merge(nullable: true), createdAt: DATETIME, updatedAt: DATETIME
        }),
        Translations: { type: :object, additionalProperties: true, description: 'Nested translation keys, e.g. board.sort_by_box.title' }
      }
    end
  end
end
