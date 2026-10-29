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
        OAuthProvider: object({ id: INTEGER, name: STRING, logo: NULLABLE_STRING, startUrl: STRING }),
        TenantSettings: object({
          brandDisplay: { type: :string, enum: %w[name_and_logo name_only logo_only no_name_no_logo] },
          logoLinksTo: { type: :string, enum: %w[root_page custom_url nothing] }, logoCustomUrl: NULLABLE_STRING, rootBoardId: NULLABLE_INTEGER,
          showRoadmapInHeader: BOOLEAN, roadmapEnabled: BOOLEAN, defaultPostSorting: { type: :string, enum: %w[trending newest most_voted oldest] }, customLinks: { type: :array, items: { type: :object, properties: { label: STRING, url: STRING } }, description: 'Extra header links' },
          loginOnlyWithOauth: BOOLEAN,
          emailRegistrationPolicy: { type: :string, enum: %w[all_allowed custom_domains_allowed none_allowed] },
          showVoteCount: BOOLEAN, showVoteButtonInBoard: BOOLEAN, showPoweredBy: BOOLEAN,
          allowAnonymousFeedback: BOOLEAN, isPrivate: BOOLEAN, hideUnusedStatusesInFilterByStatus: BOOLEAN, customCss: NULLABLE_STRING
        }),
        Tenant: object({
          siteName: STRING, siteLogo: NULLABLE_STRING, siteFavicon: NULLABLE_STRING, locale: STRING,
          oauthProviders: { type: :array, items: ref(:OAuthProvider) },
          settings: ref(:TenantSettings)
        }),
        Session: object({ csrfToken: STRING, user: ref(:CurrentUser).merge(nullable: true), aiEnabled: BOOLEAN.merge(description: 'True for moderators when an AI provider is configured'), pendingPostsCount: NULLABLE_INTEGER.merge(description: 'Posts waiting for approval; null unless the user is a moderator'), tenant: ref(:Tenant) }),
        LoginInput: object({ email: STRING, password: STRING, rememberMe: BOOLEAN }, required: %i[email password]),
        RegisterInput: object({
          fullName: STRING, email: STRING, password: STRING, passwordConfirmation: STRING, invitationToken: NULLABLE_STRING
        }, required: %i[fullName email password passwordConfirmation]),
        RegistrationResult: object({ confirmationRequired: BOOLEAN, message: STRING, session: ref(:Session) }),
        ForgotPasswordInput: object({ email: STRING }),
        ResetPasswordInput: object({ resetPasswordToken: STRING, password: STRING, passwordConfirmation: STRING }),
        PasswordResetResponse: object({ message: STRING, session: ref(:Session) }),
        MessageResponse: object({ message: STRING }),
        Board: object({ id: INTEGER, name: STRING, slug: STRING, description: NULLABLE_STRING }),
        PostStatus: object({ id: INTEGER, name: STRING, color: STRING, order: INTEGER, showInRoadmap: BOOLEAN }),
        PostListItem: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, postStatusId: NULLABLE_INTEGER,
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, createdAt: DATETIME
        }),
        PostPage: object({ posts: { type: :array, items: ref(:PostListItem) }, page: INTEGER, hasMore: BOOLEAN }),
        RoadmapPost: object({
          id: INTEGER, slug: STRING, title: STRING, boardId: INTEGER,
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, updatedAt: DATETIME
        }),
        RoadmapColumn: object({
          status: ref(:PostStatus), posts: { type: :array, items: ref(:RoadmapPost) },
          postsCount: { type: :integer, description: 'All posts in this status; posts holds at most 100' }
        }),
        Roadmap: object({ columns: { type: :array, items: ref(:RoadmapColumn) } }),
        Post: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, boardId: INTEGER, postStatusId: NULLABLE_INTEGER,
          approvalStatus: { type: :string, enum: %w[approved pending rejected] }, author: ref(:Author).merge(nullable: true),
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, followed: BOOLEAN, createdAt: DATETIME, updatedAt: DATETIME
        }),
        ModerationPost: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, boardId: INTEGER,
          approvalStatus: { type: :string, enum: %w[pending rejected] }, author: ref(:Author).merge(nullable: true), createdAt: DATETIME
        }),
        ModerationQueue: object({
          posts: { type: :array, items: ref(:ModerationPost), description: 'Newest first, at most 100' },
          pendingCount: INTEGER,
          allowAnonymousFeedback: BOOLEAN,
          feedbackApprovalPolicy: { type: :string, enum: %w[anonymous_require_approval never_require_approval always_require_approval] }
        }),
        ModerationUser: object({
          id: INTEGER, email: STRING, fullName: STRING, avatarUrl: STRING,
          role: { type: :string, enum: %w[user moderator admin owner] },
          status: { type: :string, enum: %w[active blocked deleted] },
          createdAt: DATETIME,
          canChangeStatus: BOOLEAN.merge(description: 'The current user may block or unblock this user'),
          canChangeRole: BOOLEAN.merge(description: 'The current user (an admin) may change the role')
        }),
        ModerationUserPage: object({
          users: { type: :array, items: ref(:ModerationUser) }, page: INTEGER, hasMore: BOOLEAN,
          counts: object({ total: INTEGER, active: INTEGER, blocked: INTEGER, deleted: INTEGER })
        }),
        UpdateModerationUser: object({
          role: { type: :string, enum: %w[user moderator admin], description: 'Admins only' },
          status: { type: :string, enum: %w[active blocked] }
        }, required: []),
        VoteState: object({ liked: BOOLEAN, likesCount: INTEGER }),
        FollowState: object({ followed: BOOLEAN }),
        Summary: object({ summary: STRING }),
        NewPost: object({
          title: STRING, description: NULLABLE_STRING, isAnonymous: BOOLEAN, postStatusId: NULLABLE_INTEGER,
          honeypot: { type: :string, description: 'Hidden form field, must stay empty' },
          formFillMs: { type: :integer, description: 'Milliseconds the form was open before it was sent (anti-spam)' }
        }, required: %i[title formFillMs]),
        UpdatePost: object({
          title: STRING, description: NULLABLE_STRING, boardId: INTEGER,
          postStatusId: NULLABLE_INTEGER, approvalStatus: { type: :string, enum: %w[approved pending rejected] }
        }, required: []),
        NewComment: object({ body: STRING, parentId: NULLABLE_INTEGER, isPostUpdate: BOOLEAN }, required: %i[body]),
        UpdateComment: object({ body: STRING, isPostUpdate: BOOLEAN }, required: []),
        Comment: object({
          id: INTEGER, body: STRING, parentId: NULLABLE_INTEGER, isPostUpdate: BOOLEAN,
          author: ref(:Author).merge(nullable: true), createdAt: DATETIME, updatedAt: DATETIME
        }),
        Translations: { type: :object, additionalProperties: true, description: 'Nested translation keys, e.g. board.sort_by_box.title' }
      }
    end
  end
end
