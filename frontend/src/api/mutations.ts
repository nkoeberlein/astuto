import {
  type InfiniteData,
  type QueryClient,
  useMutation,
  useQueryClient,
} from '@tanstack/react-query'
import {
  api,
  type Comment,
  type Post,
  type PostPage,
  type Schemas,
  type Session,
  setCsrfToken,
  unwrap,
} from './client'
import { commentsQuery, postQuery, sessionQuery } from './queries'

type VoteState = Schemas['VoteState']
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
    onSuccess: (session) => applySession(queryClient, session),
  })
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
