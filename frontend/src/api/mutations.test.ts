import { type InfiniteData, QueryClient } from '@tanstack/react-query'
import { describe, expect, it } from 'vitest'
import type { Post, PostPage } from './client'
import { applyVote } from './mutations'
import { postQuery } from './queries'

const listItem = (id: number) => ({
  id,
  slug: `post-${id}`,
  title: `Post ${id}`,
  description: null,
  postStatusId: null,
  likesCount: 3,
  commentsCount: 0,
  liked: false,
  createdAt: '2026-10-20T10:00:00Z',
})

describe('applyVote', () => {
  it('updates the post detail and every board list that contains the post', () => {
    const queryClient = new QueryClient()
    const listKey = [
      'boards',
      'features',
      'posts',
      { search: '', sortBy: 'trending', statusIds: [] },
    ]
    queryClient.setQueryData<InfiniteData<PostPage>>(listKey, {
      pages: [{ posts: [listItem(1), listItem(2)], page: 1, hasMore: false }],
      pageParams: [1],
    })
    queryClient.setQueryData(postQuery('post-1').queryKey, { ...listItem(1) } as unknown as Post)
    queryClient.setQueryData(
      ['boards'],
      [{ id: 9, name: 'Features', slug: 'features', description: null }],
    )

    applyVote(queryClient, 1, 'post-1', { liked: true, likesCount: 4 })

    const list = queryClient.getQueryData<InfiniteData<PostPage>>(listKey)
    expect(list?.pages[0]?.posts.map((p) => [p.id, p.liked, p.likesCount])).toEqual([
      [1, true, 4],
      [2, false, 3],
    ])
    expect(queryClient.getQueryData<Post>(postQuery('post-1').queryKey)).toMatchObject({
      liked: true,
      likesCount: 4,
    })
    // Other queries under ['boards'] (the board list) stay untouched
    expect(queryClient.getQueryData(['boards'])).toHaveLength(1)
  })
})
