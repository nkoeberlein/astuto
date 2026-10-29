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
        Author: object({ id: INTEGER, fullName: STRING, avatarUrl: NULLABLE_STRING.merge(description: 'null when Gravatar is switched off') }),
        CurrentUser: object({ id: INTEGER, email: STRING, fullName: STRING, role: { type: :string, enum: %w[user moderator admin owner] }, avatarUrl: NULLABLE_STRING, twoFactorSetupRequired: BOOLEAN.merge(description: 'Staff must set up 2FA before moderating (TenantSetting require_two_factor_for_staff)') }),
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
          ldapLabel: NULLABLE_STRING.merge(description: 'Name of the company account when LDAP login is on'),
          hasChangelog: BOOLEAN.merge(description: 'At least one published changelog entry (header link)'),
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
        EmailInput: object({ email: STRING }),
        ResetPasswordInput: object({ resetPasswordToken: STRING, password: STRING, passwordConfirmation: STRING }),
        PasswordResetResponse: object({ message: STRING, session: ref(:Session) }),
        MessageResponse: object({ message: STRING }),
        Board: object({ id: INTEGER, name: STRING, slug: STRING, description: NULLABLE_STRING, visibility: { type: :string, enum: %w[everyone signed_in staff], description: 'Who sees the board and its posts (private boards)' } }),
        PostStatus: object({ id: INTEGER, name: STRING, color: STRING, order: INTEGER, showInRoadmap: BOOLEAN }),
        Tag: object({ id: INTEGER, name: STRING, color: STRING, order: INTEGER }),
        TagInput: object({ name: STRING, color: STRING.merge(description: 'Hex color, e.g. #64748b') }, required: []),
        PostListItem: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, postStatusId: NULLABLE_INTEGER,
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, createdAt: DATETIME,
          tagIds: { type: :array, items: INTEGER, description: 'Tags in their order' }
        }),
        PostPage: object({ posts: { type: :array, items: ref(:PostListItem) }, page: INTEGER, hasMore: BOOLEAN }),
        MyPost: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, postStatusId: NULLABLE_INTEGER,
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, createdAt: DATETIME, updatedAt: DATETIME,
          board: object({ name: STRING, slug: STRING }, nullable: true), tagIds: { type: :array, items: INTEGER, description: 'Tags in their order' },
          approvalStatus: { type: :string, enum: %w[approved pending rejected merged] }
        }),
        MyPostPage: object({
          filter: { type: :string, enum: MyPostsQuery::FILTERS },
          counts: object({ created: INTEGER, voted: INTEGER, followed: INTEGER }),
          posts: { type: :array, items: ref(:MyPost) }, page: INTEGER, hasMore: BOOLEAN
        }),
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
          likesCount: INTEGER, commentsCount: INTEGER, liked: BOOLEAN, followed: BOOLEAN, tagIds: { type: :array, items: INTEGER, description: 'Tags in their order' },
          source: object({ url: NULLABLE_STRING, label: NULLABLE_STRING }, nullable: true).merge(description: 'Where the feedback came from; moderators only'),
          mergedPosts: { type: :array, items: object({ title: STRING }), description: 'Duplicates merged into this post' },
          changelogEntries: { type: :array, items: object({ id: INTEGER, title: STRING }), description: 'Published changelog entries that deliver this post' },
          createdAt: DATETIME, updatedAt: DATETIME
        }),
        ModerationPost: object({
          id: INTEGER, slug: STRING, title: STRING, description: NULLABLE_STRING, boardId: INTEGER,
          approvalStatus: { type: :string, enum: %w[pending rejected] }, author: ref(:Author).merge(nullable: true), createdAt: DATETIME
        }),
        ModerationQueue: object({
          posts: { type: :array, items: ref(:ModerationPost), description: 'Newest first, at most 100' },
          pendingCount: INTEGER,
          allowAnonymousFeedback: BOOLEAN,
          feedbackApprovalPolicy: { type: :string, enum: TenantSetting.feedback_approval_policies.keys }
        }),
        ModerationUser: object({
          id: INTEGER, email: STRING, fullName: STRING, avatarUrl: NULLABLE_STRING,
          role: { type: :string, enum: %w[user moderator admin owner] },
          status: { type: :string, enum: %w[active blocked deleted] },
          createdAt: DATETIME,
          canChangeStatus: BOOLEAN.merge(description: 'The current user may block or unblock this user'),
          canChangeRole: BOOLEAN.merge(description: 'The current user (an admin) may change the role'),
          canExport: BOOLEAN.merge(description: 'Admins may download the stored data'),
          canDelete: BOOLEAN.merge(description: 'The current user (an admin) may delete the account')
        }),
        UserDataExport: { type: :object, description: 'Everything stored about a person: profile, posts, comments, votes, follows', additionalProperties: true },
        ModerationUserPage: object({
          users: { type: :array, items: ref(:ModerationUser) }, page: INTEGER, hasMore: BOOLEAN,
          counts: object({ total: INTEGER, active: INTEGER, blocked: INTEGER, deleted: INTEGER })
        }),
        UpdateModerationUser: object({
          role: { type: :string, enum: %w[user moderator admin], description: 'Admins only' },
          status: { type: :string, enum: %w[active blocked] }
        }, required: []),
        GeneralSettings: object({
          siteName: STRING, siteLogo: NULLABLE_STRING, siteFavicon: NULLABLE_STRING, locale: STRING, customDomain: NULLABLE_STRING,
          brandDisplay: { type: :string, enum: %w[name_and_logo name_only logo_only no_name_no_logo] },
          useBrowserLocale: BOOLEAN, rootBoardId: INTEGER.merge(description: '0 shows the roadmap (or the first board) on the home page'),
          defaultPostSorting: { type: :string, enum: %w[trending newest most_voted oldest] },
          customLinks: { type: :array, items: ref(:CustomLink) },
          isPrivate: BOOLEAN, useGravatar: BOOLEAN.merge(description: 'Avatars from gravatar.com (sends the email hash there)'), requireTwoFactorForStaff: BOOLEAN, allowAnonymousFeedback: BOOLEAN,
          feedbackApprovalPolicy: { type: :string, enum: TenantSetting.feedback_approval_policies.keys },
          trustedAfterPosts: INTEGER.merge(description: 'Approved posts after which an account is trusted (policy new_users_require_approval)'),
          loginOnlyWithOauth: BOOLEAN,
          logoLinksTo: { type: :string, enum: %w[root_page custom_url nothing] }, logoCustomUrl: NULLABLE_STRING,
          roadmapEnabled: BOOLEAN, showRoadmapInHeader: BOOLEAN,
          collapseBoardsInHeader: { type: :string, enum: %w[no_collapse always_collapse] },
          mailLogoSize: INTEGER, showVoteCount: BOOLEAN, showVoteButtonInBoard: BOOLEAN,
          hideUnusedStatusesInFilterByStatus: BOOLEAN, showPoweredBy: BOOLEAN, customCss: NULLABLE_STRING,
          emailRegistrationPolicy: { type: :string, enum: %w[all_allowed custom_domains_allowed none_allowed] },
          allowedEmailDomains: NULLABLE_STRING.merge(description: 'Comma-separated, for custom_domains_allowed'),
          multiTenancy: BOOLEAN.merge(description: 'Custom domains only exist with MULTI_TENANCY=true'),
          availableLocales: { type: :array, items: STRING }
        }),
        UpdateGeneralSettings: object({
          siteName: STRING, siteLogo: NULLABLE_STRING, siteFavicon: NULLABLE_STRING, locale: STRING, customDomain: NULLABLE_STRING,
          brandDisplay: { type: :string, enum: %w[name_and_logo name_only logo_only no_name_no_logo] },
          useBrowserLocale: BOOLEAN, rootBoardId: INTEGER,
          defaultPostSorting: { type: :string, enum: %w[trending newest most_voted oldest] },
          customLinks: { type: :array, items: ref(:CustomLink) },
          isPrivate: BOOLEAN, useGravatar: BOOLEAN.merge(description: 'Avatars from gravatar.com (sends the email hash there)'), requireTwoFactorForStaff: BOOLEAN, allowAnonymousFeedback: BOOLEAN,
          feedbackApprovalPolicy: { type: :string, enum: TenantSetting.feedback_approval_policies.keys },
          trustedAfterPosts: INTEGER.merge(description: 'Approved posts after which an account is trusted (policy new_users_require_approval)'),
          loginOnlyWithOauth: BOOLEAN,
          logoLinksTo: { type: :string, enum: %w[root_page custom_url nothing] }, logoCustomUrl: NULLABLE_STRING,
          roadmapEnabled: BOOLEAN, showRoadmapInHeader: BOOLEAN,
          collapseBoardsInHeader: { type: :string, enum: %w[no_collapse always_collapse] },
          mailLogoSize: INTEGER, showVoteCount: BOOLEAN, showVoteButtonInBoard: BOOLEAN,
          hideUnusedStatusesInFilterByStatus: BOOLEAN, showPoweredBy: BOOLEAN, customCss: NULLABLE_STRING,
          emailRegistrationPolicy: { type: :string, enum: %w[all_allowed custom_domains_allowed none_allowed] },
          allowedEmailDomains: NULLABLE_STRING
        }, required: []),
        CustomLink: object({ label: STRING, url: STRING }),
        BoardInput: object({
          name: STRING, description: NULLABLE_STRING,
          slug: NULLABLE_STRING.merge(description: 'URL part; blank generates one from the name'),
          visibility: { type: :string, enum: %w[everyone signed_in staff], description: 'Who sees the board and its posts (private boards)' }
        }, required: []),
        PostStatusInput: object({ name: STRING, color: STRING.merge(description: 'Hex color, e.g. #0077cc'), showInRoadmap: BOOLEAN }, required: []),
        Reorder: object({ ids: { type: :array, items: INTEGER, description: 'Every id, in the new order' } }),
        OAuthSettings: object({
          id: INTEGER, name: STRING, logo: NULLABLE_STRING,
          isEnabled: BOOLEAN.merge(description: 'For default providers: switched on for this feedback space'),
          isDefault: BOOLEAN.merge(description: 'Set up by the instance; only isEnabled can be changed'),
          clientId: NULLABLE_STRING, authorizeUrl: NULLABLE_STRING, tokenUrl: NULLABLE_STRING, profileUrl: NULLABLE_STRING,
          scope: NULLABLE_STRING, jsonUserNamePath: NULLABLE_STRING, jsonUserEmailPath: NULLABLE_STRING,
          profileHeaders: { type: :array, items: ref(:WebhookHeader), description: 'Extra headers of the profile request (#485)' },
          callbackUrl: STRING, testUrl: STRING
        }),
        OAuthInput: object({
          name: STRING, logo: NULLABLE_STRING, isEnabled: BOOLEAN, clientId: STRING,
          clientSecret: STRING.merge(description: 'Write-only; blank on update keeps the current secret'),
          authorizeUrl: STRING, tokenUrl: STRING, profileUrl: STRING, scope: STRING,
          jsonUserNamePath: NULLABLE_STRING, jsonUserEmailPath: STRING,
          profileHeaders: { type: :array, items: ref(:WebhookHeader) }
        }, required: []),
        WebhookHeader: object({ key: STRING, value: STRING }),
        Webhook: object({
          id: INTEGER, name: STRING, description: NULLABLE_STRING, isEnabled: BOOLEAN,
          trigger: { type: :string, enum: %w[new_post new_post_pending_approval delete_post post_status_change new_comment new_vote new_user] },
          httpMethod: { type: :string, enum: %w[post put patch delete] },
          url: STRING.merge(description: 'Liquid template'), httpBody: NULLABLE_STRING.merge(description: 'Liquid template that renders JSON'),
          httpHeaders: { type: :array, items: ref(:WebhookHeader) },
          signingSecret: STRING.merge(description: 'Key of the X-Astuto-Signature HMAC'),
          lastDelivery: ref(:WebhookDelivery).merge(nullable: true)
        }),
        WebhookDelivery: object({
          id: INTEGER, success: BOOLEAN, isTest: BOOLEAN, httpStatus: NULLABLE_INTEGER, durationMs: NULLABLE_INTEGER,
          error: NULLABLE_STRING, responseBody: NULLABLE_STRING, createdAt: DATETIME
        }),
        WebhookInput: object({
          name: STRING, description: NULLABLE_STRING, isEnabled: BOOLEAN,
          trigger: { type: :string, enum: %w[new_post new_post_pending_approval delete_post post_status_change new_comment new_vote new_user] },
          httpMethod: { type: :string, enum: %w[post put patch delete] },
          url: STRING, httpBody: NULLABLE_STRING, httpHeaders: { type: :array, items: ref(:WebhookHeader) }
        }, required: []),
        WebhookPreviewInput: object({ trigger: STRING, url: STRING, httpBody: NULLABLE_STRING }, required: %i[trigger url]),
        WebhookPreview: object({ url: STRING, body: STRING }),
        WebhookTestResult: object({ status: INTEGER, body: STRING.merge(description: 'Response body, at most 4000 characters') }),
        WebhookVariables: { type: :object, additionalProperties: { type: :array, items: STRING }, description: 'Template variables per trigger, e.g. post.title' },
        WebhookTemplates: object(
          WebhookTemplates::SERVICES.index_with { { type: :object, additionalProperties: STRING, description: 'Liquid body per trigger' } }
        ),
        SamlSettings: object({
          enabled: BOOLEAN, label: STRING.merge(description: 'Text of the login button'),
          idpEntityId: NULLABLE_STRING, idpSsoUrl: NULLABLE_STRING, idpCert: NULLABLE_STRING.merge(description: 'PEM certificate the IdP signs with'),
          emailAttribute: NULLABLE_STRING.merge(description: 'Blank: common attribute names, then the NameID'), nameAttribute: NULLABLE_STRING,
          autoCreateUsers: BOOLEAN, spEntityId: STRING.merge(description: 'Entity ID (and metadata URL) of Astuto for the IdP'), acsUrl: STRING
        }),
        UpdateSamlSettings: object({
          enabled: BOOLEAN, label: STRING, idpEntityId: NULLABLE_STRING, idpSsoUrl: NULLABLE_STRING, idpCert: NULLABLE_STRING,
          emailAttribute: NULLABLE_STRING, nameAttribute: NULLABLE_STRING, autoCreateUsers: BOOLEAN
        }, required: []),
        SamlMetadataInput: object({ xml: STRING }),
        LdapSettings: object({
          enabled: BOOLEAN, label: STRING, host: NULLABLE_STRING, port: INTEGER,
          encryption: { type: :string, enum: %w[plain start_tls simple_tls] }, verifyCertificate: BOOLEAN,
          baseDn: NULLABLE_STRING, bindDn: NULLABLE_STRING, bindPasswordSet: BOOLEAN.merge(description: 'The password itself is never sent'),
          userFilter: STRING.merge(description: '%{login} stands for the escaped login name'), emailAttribute: STRING, nameAttribute: STRING,
          autoCreateUsers: BOOLEAN
        }),
        UpdateLdapSettings: object({
          enabled: BOOLEAN, label: STRING, host: NULLABLE_STRING, port: INTEGER,
          encryption: { type: :string, enum: %w[plain start_tls simple_tls] }, verifyCertificate: BOOLEAN,
          baseDn: NULLABLE_STRING, bindDn: NULLABLE_STRING, bindPassword: STRING.merge(description: 'Blank keeps the current one'),
          userFilter: STRING, emailAttribute: STRING, nameAttribute: STRING, autoCreateUsers: BOOLEAN
        }, required: []),
        LdapTestInput: object({ login: STRING }),
        LdapTestResult: object({ dn: STRING, email: NULLABLE_STRING, name: NULLABLE_STRING }),
        LdapLoginInput: object({ login: STRING, password: STRING, rememberMe: BOOLEAN }, required: %i[login password]),
        SamlIdpFields: object({ idpEntityId: NULLABLE_STRING, idpSsoUrl: STRING, idpCert: NULLABLE_STRING }),
        AuditChange: object({ field: STRING.merge(description: 'model.attribute, e.g. post.post_status_id'), from: { description: 'Any JSON value; "[filtered]" for secrets' }, to: { description: 'Any JSON value' } }),
        AuditEvent: object({
          id: INTEGER, createdAt: DATETIME, action: STRING.merge(description: 'category.verb, e.g. post.update, webhook.rotate_secret'),
          actorName: NULLABLE_STRING, subjectType: NULLABLE_STRING, subjectLabel: NULLABLE_STRING,
          subjectPath: NULLABLE_STRING.merge(description: 'Link to the post while it exists'),
          changes: { type: :array, items: ref(:AuditChange) }, source: { type: :string, enum: %w[app api mcp] }, ip: NULLABLE_STRING
        }),
        AuditEventPage: object({ events: { type: :array, items: ref(:AuditEvent) }, nextBefore: NULLABLE_INTEGER }),
        Invitation: object({
          id: INTEGER, email: STRING, status: { type: :string, enum: %w[pending accepted expired] },
          sentAt: DATETIME, acceptedAt: { type: :string, format: 'date-time', nullable: true }
        }),
        InvitationInput: object({
          to: { type: :array, items: STRING, description: 'At most 20 addresses' },
          subject: STRING, body: STRING.merge(description: 'Must contain %link%')
        }),
        InvitationTestInput: object({ subject: STRING, body: STRING }),
        InvitationResult: object({ sent: INTEGER, skipped: { type: :array, items: STRING, description: 'Invalid, registered or already accepted' } }),
        InvitationTestResult: object({ sentTo: STRING }),
        Profile: object({
          fullName: STRING, email: STRING, unconfirmedEmail: NULLABLE_STRING.merge(description: 'New email waiting for confirmation'),
          hasSetPassword: BOOLEAN.merge(description: 'False for accounts created via OAuth'),
          notificationsEnabled: BOOLEAN,
          recapNotificationFrequency: { type: :string, enum: %w[never daily weekly monthly] },
          recapAvailable: BOOLEAN.merge(description: 'Recap emails need Sidekiq'),
          canHaveApiKey: BOOLEAN, apiKey: NULLABLE_STRING.merge(description: 'Masked prefix of the current API key'),
          canDeleteAccount: BOOLEAN.merge(description: 'False for the owner'),
          twoFactorEnabled: BOOLEAN, twoFactorRequired: BOOLEAN.merge(description: 'Required for this staff member by the site settings'),
          backupCodesLeft: INTEGER
        }),
        TwoFactorRequired: object({ twoFactorRequired: BOOLEAN }),
        TwoFactorCodeInput: object({ code: STRING.merge(description: '6-digit code from the app or a backup code') }),
        TwoFactorSetup: object({ secret: STRING.merge(description: 'For manual entry, in groups of four'), otpauthUri: STRING, qrCode: STRING.merge(description: 'data: URI of an SVG QR code') }),
        TwoFactorBackupCodes: object({ backupCodes: { type: :array, items: STRING } }),
        TwoFactorDisableInput: object({ currentPassword: STRING, code: STRING }, required: []),
        UpdateProfile: object({
          fullName: STRING, notificationsEnabled: BOOLEAN,
          recapNotificationFrequency: { type: :string, enum: %w[never daily weekly monthly] },
          email: STRING, password: STRING, passwordConfirmation: STRING,
          currentPassword: STRING.merge(description: 'Needed to change email or password')
        }, required: []),
        DeleteProfile: object({ currentPassword: STRING }, required: []),
        NewApiKey: object({ apiKey: STRING.merge(description: 'Shown only once'), masked: STRING }),
        TestEmailResult: object({ sentTo: STRING, deliveryMethod: STRING, from: STRING }),
        VoteState: object({ liked: BOOLEAN, likesCount: INTEGER }),
        FollowState: object({ followed: BOOLEAN }),
        Summary: object({ summary: STRING }),
        Suggestion: object({ boardId: NULLABLE_INTEGER, tagIds: { type: :array, items: INTEGER } }),
        ChangelogEntry: object({
          id: INTEGER, title: STRING, body: STRING, publishedAt: { type: :string, format: 'date-time', nullable: true, description: 'null for drafts' },
          posts: { type: :array, items: object({ id: INTEGER, title: STRING, slug: STRING }) }
        }),
        ChangelogEntryPage: object({ entries: { type: :array, items: ref(:ChangelogEntry) }, page: INTEGER, hasMore: BOOLEAN }),
        ChangelogEntryInput: object({
          title: STRING, body: STRING, postIds: { type: :array, items: INTEGER },
          published: BOOLEAN.merge(description: 'true publishes a draft (first time: emails the followers of the linked posts), false turns it back into a draft')
        }, required: []),
        LinkablePost: object({ id: INTEGER, title: STRING, slug: STRING, postStatusId: NULLABLE_INTEGER }),
        ChangelogDraftInput: object({ postIds: { type: :array, items: INTEGER } }),
        ChangelogDraft: object({ body: STRING }),
        WidgetSessionInput: object({ token: STRING.merge(description: 'Visitor token: HS256 JWT signed with the widget secret (claims email, name, id, exp)') }),
        WidgetSession: object({ accessToken: STRING.merge(description: 'Send as Authorization: Bearer'), expiresAt: DATETIME }),
        WidgetSettings: object({
          enabled: BOOLEAN, secret: STRING.merge(description: 'Signs visitor tokens; keep it on your server'),
          allowedOrigins: STRING.merge(description: 'Sites that may show the widget, one origin per line (empty: any)'),
          autoCreateUsers: BOOLEAN
        }),
        UpdateWidgetSettings: object({ enabled: BOOLEAN, allowedOrigins: STRING, autoCreateUsers: BOOLEAN }, required: []),
        PostTranslation: object({ title: STRING, description: NULLABLE_STRING, locale: STRING }),
        CommentTranslation: object({ body: STRING, locale: STRING }),
        NewPost: object({
          title: STRING, description: NULLABLE_STRING, isAnonymous: BOOLEAN, postStatusId: NULLABLE_INTEGER,
          honeypot: { type: :string, description: 'Hidden form field, must stay empty' },
          formFillMs: { type: :integer, description: 'Milliseconds the form was open before it was sent (anti-spam)' }
        }, required: %i[title formFillMs]),
        MergePostInput: object({ targetId: INTEGER.merge(description: 'Post that stays and takes over votes, followers and comments') }),
        UpdatePost: object({
          title: STRING, description: NULLABLE_STRING, boardId: INTEGER,
          postStatusId: NULLABLE_INTEGER, approvalStatus: { type: :string, enum: %w[approved pending rejected] },
          sourceUrl: NULLABLE_STRING.merge(description: 'Moderators only'), sourceLabel: NULLABLE_STRING.merge(description: 'Moderators only'),
          tagIds: { type: :array, items: INTEGER, description: 'Moderators only; replaces the tags of the post' }
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
