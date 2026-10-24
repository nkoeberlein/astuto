import {
  type InfiniteData,
  type QueryClient,
  useMutation,
  useQueryClient,
} from '@tanstack/react-query'
import { api, type Comment, type Post, type PostPage, type Schemas, unwrap } from './client'
import { commentsQuery, postQuery } from './queries'

type VoteState = Schemas['VoteState']
export type NewPost = Schemas['NewPost']
export type NewComment = Schemas['NewComment']

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
