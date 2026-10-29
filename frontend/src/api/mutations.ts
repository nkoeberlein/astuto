import {
  type InfiniteData,
  type QueryClient,
  useMutation,
  useQueryClient,
} from '@tanstack/react-query'
import { applyModeration } from '@/features/moderation/queue'
import { replaceUser } from '@/features/moderation/users'
import {
  api,
  type Board,
  type BoardInput,
  type Comment,
  type GeneralSettings,
  type LdapLoginInput,
  type OAuthInput,
  type Post,
  type PostPage,
  type PostStatus,
  type PostStatusInput,
  type Profile,
  type Schemas,
  type Session,
  setCsrfToken,
  type UpdateGeneralSettings,
  type UpdateLdapSettings,
  type UpdateProfile,
  type UpdateSamlSettings,
  unwrap,
  type WebhookInput,
} from './client'
import {
  boardsQuery,
  commentsQuery,
  generalSettingsQuery,
  ldapSettingsQuery,
  moderationPostsQuery,
  postQuery,
  postStatusesQuery,
  profileQuery,
  samlSettingsQuery,
  sessionQuery,
} from './queries'

type VoteState = Schemas['VoteState']
type ModerationQueue = Schemas['ModerationQueue']
type ModerationUserPage = Schemas['ModerationUserPage']
export type UpdateModerationUser = Schemas['UpdateModerationUser']
export type NewPost = Schemas['NewPost']
export type UpdatePost = Schemas['UpdatePost']
export type NewComment = Schemas['NewComment']
export type UpdateComment = Schemas['UpdateComment']
export type LoginInput = Schemas['LoginInput']
export type RegisterInput = Schemas['RegisterInput']
export type RegistrationResult = Schemas['RegistrationResult']
export type ForgotPasswordInput = Schemas['ForgotPasswordInput']
export type ResetPasswordInput = Schemas['ResetPasswordInput']

// Syncs a new session (after login, logout, registration, or password reset) into the cache
export function applySession(queryClient: QueryClient, session: Session) {
  setCsrfToken(session.csrfToken)
  queryClient.setQueryData<Session>(sessionQuery.queryKey, session)
  void queryClient.invalidateQueries({ queryKey: ['boards'] })
  void queryClient.invalidateQueries({ queryKey: ['posts'] })
  void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
}

// Board post lists have keys like ['boards', slug, 'posts', filters]
const isBoardPostList = {
  queryKey: ['boards'],
  predicate: (q: { queryKey: readonly unknown[] }) => q.queryKey[2] === 'posts',
}

// Writes a vote state into the post detail and every cached board list containing the post
export function applyVote(
  queryClient: QueryClient,
  postId: number,
  postSlug: string,
  state: VoteState,
) {
  queryClient.setQueryData<Post>(
    postQuery(postSlug).queryKey,
    (post) => post && { ...post, ...state },
  )
  queryClient.setQueriesData<InfiniteData<PostPage>>(isBoardPostList, (data) =>
    data
      ? {
          ...data,
          pages: data.pages.map((page) => ({
            ...page,
            posts: page.posts.map((p) => (p.id === postId ? { ...p, ...state } : p)),
          })),
        }
      : data,
  )
}

// Optimistic: the count changes immediately and is rolled back if the request fails
export function useVote(post: { id: number; slug: string; liked: boolean; likesCount: number }) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (liked: boolean) => {
      const options = { params: { path: { post_id: post.slug } } }
      return unwrap(
        liked
          ? api.POST('/api/app/v1/posts/{post_id}/vote', options)
          : api.DELETE('/api/app/v1/posts/{post_id}/vote', options),
      )
    },
    onMutate: (liked) => {
      const previous = { liked: post.liked, likesCount: post.likesCount }
      applyVote(queryClient, post.id, post.slug, {
        liked,
        likesCount: post.likesCount + (liked ? 1 : -1),
      })
      return { previous }
    },
    onError: (_error, _liked, context) => {
      if (context) applyVote(queryClient, post.id, post.slug, context.previous)
    },
    onSuccess: (state) => applyVote(queryClient, post.id, post.slug, state),
  })
}

export function useFollow(postSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (followed: boolean) => {
      const options = { params: { path: { post_id: postSlug } } }
      return unwrap(
        followed
          ? api.POST('/api/app/v1/posts/{post_id}/follow', options)
          : api.DELETE('/api/app/v1/posts/{post_id}/follow', options),
      )
    },
    onSuccess: ({ followed }) =>
      queryClient.setQueryData<Post>(postQuery(postSlug).queryKey, (p) => p && { ...p, followed }),
  })
}

export function useCreateComment(postSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (comment: NewComment) =>
      unwrap(
        api.POST('/api/app/v1/posts/{post_id}/comments', {
          params: { path: { post_id: postSlug } },
          body: comment,
        }),
      ),
    onSuccess: (comment) => {
      queryClient.setQueryData<Comment[]>(commentsQuery(postSlug).queryKey, (comments) =>
        comments ? [...comments, comment] : [comment],
      )
      queryClient.setQueryData<Post>(
        postQuery(postSlug).queryKey,
        (p) => p && { ...p, commentsCount: p.commentsCount + 1 },
      )
      void queryClient.invalidateQueries(isBoardPostList)
    },
  })
}

export function useCreatePost(boardSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (post: NewPost) =>
      unwrap(
        api.POST('/api/app/v1/boards/{board_id}/posts', {
          params: { path: { board_id: boardSlug } },
          body: post,
        }),
      ),
    onSuccess: () => queryClient.invalidateQueries(isBoardPostList),
  })
}

export function useUpdatePost(postSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (changes: UpdatePost) =>
      unwrap(
        api.PATCH('/api/app/v1/posts/{id}', {
          params: { path: { id: postSlug } },
          body: changes,
        }),
      ),
    onSuccess: (updated) => {
      queryClient.setQueryData<Post>(postQuery(postSlug).queryKey, updated)
      void queryClient.invalidateQueries(isBoardPostList)
      void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
    },
  })
}

export function useDeletePost(postSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: () =>
      unwrap(
        api.DELETE('/api/app/v1/posts/{id}', {
          params: { path: { id: postSlug } },
        }),
      ),
    onSuccess: () => {
      queryClient.removeQueries({ queryKey: postQuery(postSlug).queryKey })
      void queryClient.invalidateQueries(isBoardPostList)
      void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
    },
  })
}

// Approve or reject a post from the feedback queue
export function useModeratePost() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (change: { id: number; approvalStatus: 'approved' | 'rejected' }) =>
      unwrap(
        api.PATCH('/api/app/v1/posts/{id}', {
          params: { path: { id: String(change.id) } },
          body: { approvalStatus: change.approvalStatus },
        }),
      ),
    onSuccess: (updated) => {
      queryClient.setQueryData<ModerationQueue>(
        moderationPostsQuery.queryKey,
        (queue) => queue && applyModeration(queue, updated.id, updated.approvalStatus),
      )
      queryClient.setQueryData<Post>(postQuery(updated.slug).queryKey, updated)
      // Pending count in the header, and approved posts appear in boards and the roadmap
      void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
      void queryClient.invalidateQueries(isBoardPostList)
      void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
    },
  })
}

// Block, unblock, or change the role of a user (moderation list)
export function useUpdateModerationUser() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...changes }: UpdateModerationUser & { id: number }) =>
      unwrap(
        api.PATCH('/api/app/v1/moderation/users/{id}', {
          params: { path: { id } },
          body: changes,
        }),
      ),
    onSuccess: (updated) => {
      // Show the change right away, then reload for the counts and the filters
      queryClient.setQueriesData<InfiniteData<ModerationUserPage>>(
        { queryKey: ['moderation', 'users'] },
        (data) => data && replaceUser(data, updated),
      )
      void queryClient.invalidateQueries({ queryKey: ['moderation', 'users'] })
    },
  })
}

// Admins delete an account like its owner could (GDPR); posts and comments stay anonymous
export function useDeleteModerationUser() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: number) =>
      unwrap(api.DELETE('/api/app/v1/moderation/users/{id}', { params: { path: { id } } })),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['moderation', 'users'] })
    },
  })
}

export function useUpdateGeneralSettings() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (changes: UpdateGeneralSettings) =>
      unwrap(api.PATCH('/api/app/v1/site_settings/general', { body: changes })),
    onSuccess: (saved) => {
      queryClient.setQueryData<GeneralSettings>(generalSettingsQuery.queryKey, saved)
      // Name, locale, header and visibility settings come with the session
      void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
      void queryClient.invalidateQueries({ queryKey: ['boards'] })
      void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
    },
  })
}

export function useUpdateComment(postSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, changes }: { id: number; changes: UpdateComment }) =>
      unwrap(
        api.PATCH('/api/app/v1/posts/{post_id}/comments/{id}', {
          params: { path: { post_id: postSlug, id } },
          body: changes,
        }),
      ),
    onSuccess: (updated) => {
      queryClient.setQueryData<Comment[]>(commentsQuery(postSlug).queryKey, (comments) =>
        comments ? comments.map((c) => (c.id === updated.id ? updated : c)) : [updated],
      )
    },
  })
}

export function useDeleteComment(postSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: number) =>
      unwrap(
        api.DELETE('/api/app/v1/posts/{post_id}/comments/{id}', {
          params: { path: { post_id: postSlug, id } },
        }),
      ),
    onSuccess: (_data, id) => {
      // Replies are deleted together with their parent (dependent: :destroy)
      const isRemoved = (c: Comment) => c.id === id || c.parentId === id
      const removed =
        queryClient.getQueryData<Comment[]>(commentsQuery(postSlug).queryKey)?.filter(isRemoved)
          .length ?? 1
      queryClient.setQueryData<Comment[]>(commentsQuery(postSlug).queryKey, (comments) =>
        comments ? comments.filter((c) => !isRemoved(c)) : [],
      )
      queryClient.setQueryData<Post>(
        postQuery(postSlug).queryKey,
        (p) => p && { ...p, commentsCount: Math.max(0, p.commentsCount - removed) },
      )
      void queryClient.invalidateQueries(isBoardPostList)
    },
  })
}

// AI summary of a post's discussion (moderators, only when the server has AI enabled)
export function useSummarizePost(postSlug: string) {
  return useMutation({
    mutationFn: () =>
      unwrap(
        api.POST('/api/app/v1/posts/{post_id}/summary', {
          params: { path: { post_id: postSlug } },
        }),
      ),
  })
}

export function useLogin() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (credentials: LoginInput) =>
      unwrap(
        api.POST('/api/app/v1/session', {
          body: credentials,
        }),
      ),
    // With two-factor authentication the password alone does not sign in yet
    onSuccess: (result) => {
      if (!('twoFactorRequired' in result)) applySession(queryClient, result)
    },
  })
}

// Login with the company directory (LDAP / Active Directory); may need the 2FA step too
export function useLdapLogin() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (credentials: LdapLoginInput) =>
      unwrap(api.POST('/api/app/v1/session/ldap', { body: credentials })),
    onSuccess: (result) => {
      if (!('twoFactorRequired' in result)) applySession(queryClient, result)
    },
  })
}

// Second login step: code from the authenticator app or a backup code
export function useTwoFactorLogin() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (code: string) =>
      unwrap(api.POST('/api/app/v1/session/two_factor', { body: { code } })),
    onSuccess: (session) => applySession(queryClient, session),
  })
}

// Profile › Two-factor authentication
export function useTwoFactorMutations() {
  const queryClient = useQueryClient()
  const refresh = () => {
    void queryClient.invalidateQueries({ queryKey: profileQuery.queryKey })
    void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
  }
  return {
    start: useMutation({
      mutationFn: (currentPassword: string) =>
        unwrap(api.POST('/api/app/v1/profile/two_factor', { body: { currentPassword } })),
    }),
    confirm: useMutation({
      mutationFn: (code: string) =>
        unwrap(api.POST('/api/app/v1/profile/two_factor/confirm', { body: { code } })),
      onSuccess: refresh,
    }),
    regenerate: useMutation({
      mutationFn: (code: string) =>
        unwrap(api.POST('/api/app/v1/profile/two_factor/backup_codes', { body: { code } })),
      onSuccess: refresh,
    }),
    disable: useMutation({
      mutationFn: (input: { currentPassword?: string; code?: string }) =>
        unwrap(api.DELETE('/api/app/v1/profile/two_factor', { body: input })),
      onSuccess: refresh,
    }),
  }
}

export function useLogout() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: () => unwrap(api.DELETE('/api/app/v1/session')),
    onSuccess: (session) => applySession(queryClient, session),
  })
}

export function useRegister() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (input: RegisterInput) =>
      unwrap(
        api.POST('/api/app/v1/registration', {
          body: input,
        }),
      ),
    onSuccess: (result) => applySession(queryClient, result.session),
  })
}

export function useForgotPassword() {
  return useMutation({
    mutationFn: (input: ForgotPasswordInput) =>
      unwrap(
        api.POST('/api/app/v1/password', {
          body: input,
        }),
      ),
  })
}

export type EmailInput = Schemas['EmailInput']

// Sends the confirmation or unlock link again (same answer whether or not the account exists)
export function useResendInstructions(kind: 'confirmation' | 'unlock') {
  return useMutation({
    mutationFn: (input: EmailInput) =>
      unwrap(
        kind === 'confirmation'
          ? api.POST('/api/app/v1/confirmation', { body: input })
          : api.POST('/api/app/v1/unlock', { body: input }),
      ),
  })
}

export function useResetPassword() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (input: ResetPasswordInput) =>
      unwrap(
        api.PATCH('/api/app/v1/password', {
          body: input,
        }),
      ),
    onSuccess: (result) => applySession(queryClient, result.session),
  })
}

// Boards and statuses (site settings, admins). Every change reloads the lists that show them.
function useInvalidateListsAfterChange() {
  const queryClient = useQueryClient()
  return () => {
    void queryClient.invalidateQueries({ queryKey: ['boards'] })
    void queryClient.invalidateQueries({ queryKey: ['postStatuses'] })
    void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
    void queryClient.invalidateQueries({ queryKey: ['posts'] })
  }
}

export function useBoardMutations() {
  const queryClient = useQueryClient()
  const onSettled = useInvalidateListsAfterChange()
  return {
    create: useMutation({
      mutationFn: (board: BoardInput) => unwrap(api.POST('/api/app/v1/boards', { body: board })),
      onSettled,
    }),
    update: useMutation({
      mutationFn: ({ id, ...board }: BoardInput & { id: number }) =>
        unwrap(
          api.PATCH('/api/app/v1/boards/{id}', {
            params: { path: { id } },
            body: board,
          }),
        ),
      onSettled,
    }),
    remove: useMutation({
      mutationFn: (id: number) =>
        unwrap(api.DELETE('/api/app/v1/boards/{id}', { params: { path: { id } } })),
      onSettled,
    }),
    reorder: useMutation({
      mutationFn: (ids: number[]) =>
        unwrap(api.PUT('/api/app/v1/boards/reorder', { body: { ids } })),
      // The new order shows at once; a failure reloads the saved one
      onMutate: (ids) => {
        queryClient.setQueryData<Board[]>(
          boardsQuery.queryKey,
          (boards) => boards && sortByIds(boards, ids),
        )
      },
      onSettled,
    }),
  }
}

export function usePostStatusMutations() {
  const queryClient = useQueryClient()
  const onSettled = useInvalidateListsAfterChange()
  return {
    create: useMutation({
      mutationFn: (status: PostStatusInput) =>
        unwrap(api.POST('/api/app/v1/post_statuses', { body: status })),
      onSettled,
    }),
    update: useMutation({
      mutationFn: ({ id, ...status }: PostStatusInput & { id: number }) =>
        unwrap(
          api.PATCH('/api/app/v1/post_statuses/{id}', { params: { path: { id } }, body: status }),
        ),
      onSettled,
    }),
    remove: useMutation({
      mutationFn: (id: number) =>
        unwrap(api.DELETE('/api/app/v1/post_statuses/{id}', { params: { path: { id } } })),
      onSettled,
    }),
    reorder: useMutation({
      mutationFn: (ids: number[]) =>
        unwrap(api.PUT('/api/app/v1/post_statuses/reorder', { body: { ids } })),
      onMutate: (ids) => {
        queryClient.setQueryData<PostStatus[]>(
          postStatusesQuery.queryKey,
          (statuses) => statuses && sortByIds(statuses, ids),
        )
      },
      onSettled,
    }),
  }
}

function sortByIds<T extends { id: number }>(items: T[], ids: number[]): T[] {
  return [...items].sort((a, b) => ids.indexOf(a.id) - ids.indexOf(b.id))
}

// OAuth providers (site settings, admins). The login page lists the enabled ones via the session.
export function useOAuthMutations() {
  const queryClient = useQueryClient()
  const onSettled = () => {
    void queryClient.invalidateQueries({ queryKey: ['siteSettings', 'oAuths'] })
    void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
  }
  return {
    create: useMutation({
      mutationFn: (oAuth: OAuthInput) =>
        unwrap(api.POST('/api/app/v1/site_settings/o_auths', { body: oAuth })),
      onSettled,
    }),
    update: useMutation({
      mutationFn: ({ id, ...oAuth }: OAuthInput & { id: number }) =>
        unwrap(
          api.PATCH('/api/app/v1/site_settings/o_auths/{id}', {
            params: { path: { id } },
            body: oAuth,
          }),
        ),
      onSettled,
    }),
    remove: useMutation({
      mutationFn: (id: number) =>
        unwrap(api.DELETE('/api/app/v1/site_settings/o_auths/{id}', { params: { path: { id } } })),
      onSettled,
    }),
    setDefaultEnabled: useMutation({
      mutationFn: ({ id, enabled }: { id: number; enabled: boolean }) =>
        unwrap(
          api.PUT('/api/app/v1/site_settings/o_auths/{id}/default', {
            params: { path: { id } },
            body: { enabled },
          }),
        ),
      onSettled,
    }),
  }
}

// Webhooks (site settings, admins)
export function useWebhookMutations() {
  const queryClient = useQueryClient()
  const onSettled = () => queryClient.invalidateQueries({ queryKey: ['siteSettings', 'webhooks'] })
  return {
    create: useMutation({
      mutationFn: (webhook: WebhookInput) =>
        unwrap(api.POST('/api/app/v1/site_settings/webhooks', { body: webhook })),
      onSettled,
    }),
    update: useMutation({
      mutationFn: ({ id, ...webhook }: WebhookInput & { id: number }) =>
        unwrap(
          api.PATCH('/api/app/v1/site_settings/webhooks/{id}', {
            params: { path: { id } },
            body: webhook,
          }),
        ),
      onSettled,
    }),
    remove: useMutation({
      mutationFn: (id: number) =>
        unwrap(api.DELETE('/api/app/v1/site_settings/webhooks/{id}', { params: { path: { id } } })),
      onSettled,
    }),
    test: useMutation({
      mutationFn: (id: number) =>
        unwrap(
          api.POST('/api/app/v1/site_settings/webhooks/{id}/test', { params: { path: { id } } }),
        ),
      // Last delivery and the delivery log change with every test, also a failed one
      onSettled,
    }),
    rotateSecret: useMutation({
      mutationFn: (id: number) =>
        unwrap(
          api.POST('/api/app/v1/site_settings/webhooks/{id}/rotate_secret', {
            params: { path: { id } },
          }),
        ),
      onSettled,
    }),
    preview: useMutation({
      mutationFn: (input: { trigger: string; url: string; httpBody: string | null }) =>
        unwrap(api.POST('/api/app/v1/site_settings/webhooks/preview', { body: input })),
    }),
  }
}

// Invitations (site settings, admins)
export function useInvitationMutations() {
  const queryClient = useQueryClient()
  return {
    send: useMutation({
      mutationFn: (input: { to: string[]; subject: string; body: string }) =>
        unwrap(api.POST('/api/app/v1/site_settings/invitations', { body: input })),
      onSettled: () => queryClient.invalidateQueries({ queryKey: ['siteSettings', 'invitations'] }),
    }),
    test: useMutation({
      mutationFn: (input: { subject: string; body: string }) =>
        unwrap(api.POST('/api/app/v1/site_settings/invitations/test', { body: input })),
    }),
  }
}

// Profile settings: changes, a new API key, deleting the account
export function useProfileMutations() {
  const queryClient = useQueryClient()
  return {
    update: useMutation({
      mutationFn: (changes: UpdateProfile) =>
        unwrap(api.PATCH('/api/app/v1/profile', { body: changes })),
      onSuccess: (profile) => {
        queryClient.setQueryData<Profile>(profileQuery.queryKey, profile)
        // Name and email show in the header
        void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
      },
    }),
    generateApiKey: useMutation({
      mutationFn: () => unwrap(api.POST('/api/app/v1/profile/api_key')),
      onSuccess: () => queryClient.invalidateQueries({ queryKey: profileQuery.queryKey }),
    }),
    remove: useMutation({
      mutationFn: (currentPassword: string) =>
        unwrap(api.DELETE('/api/app/v1/profile', { body: { currentPassword } })),
      onSuccess: (session) => {
        queryClient.removeQueries({ queryKey: profileQuery.queryKey })
        applySession(queryClient, session)
      },
    }),
  }
}

// Site settings › General: a test email to the signed-in admin
export function useSendTestEmail() {
  return useMutation({
    mutationFn: () => unwrap(api.POST('/api/app/v1/site_settings/test_email')),
  })
}

// Site settings › Authentication › SAML single sign-on
export function useSamlMutations() {
  const queryClient = useQueryClient()
  return {
    save: useMutation({
      mutationFn: (changes: UpdateSamlSettings) =>
        unwrap(api.PATCH('/api/app/v1/site_settings/saml', { body: changes })),
      onSuccess: (saved) => {
        queryClient.setQueryData(samlSettingsQuery.queryKey, saved)
        void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
      },
    }),
    parseMetadata: useMutation({
      mutationFn: (xml: string) =>
        unwrap(api.POST('/api/app/v1/site_settings/saml/parse_metadata', { body: { xml } })),
    }),
  }
}

// Site settings › Authentication › LDAP / Active Directory
export function useLdapMutations() {
  const queryClient = useQueryClient()
  return {
    save: useMutation({
      mutationFn: (changes: UpdateLdapSettings) =>
        unwrap(api.PATCH('/api/app/v1/site_settings/ldap', { body: changes })),
      onSuccess: (saved) => {
        queryClient.setQueryData(ldapSettingsQuery.queryKey, saved)
        void queryClient.invalidateQueries({ queryKey: sessionQuery.queryKey })
      },
    }),
    test: useMutation({
      mutationFn: (login: string) =>
        unwrap(api.POST('/api/app/v1/site_settings/ldap/test', { body: { login } })),
    }),
  }
}

// Moderators merge a duplicate into another post (votes, followers and comments move there)
export function useMergePost(sourceSlug: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (targetId: number) =>
      unwrap(
        api.POST('/api/app/v1/posts/{id}/merge', {
          params: { path: { id: sourceSlug } },
          body: { targetId },
        }),
      ),
    onSuccess: (target) => {
      queryClient.setQueryData(postQuery(target.slug).queryKey, target)
      queryClient.removeQueries({ queryKey: postQuery(sourceSlug).queryKey })
      void queryClient.invalidateQueries(isBoardPostList)
      void queryClient.invalidateQueries({ queryKey: ['roadmap'] })
      void queryClient.invalidateQueries({ queryKey: commentsQuery(target.slug).queryKey })
    },
  })
}
