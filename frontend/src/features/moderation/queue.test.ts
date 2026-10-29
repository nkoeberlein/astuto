import { describe, expect, it } from 'vitest'
import type { ModerationPost, ModerationQueue } from '@/api/client'
import { applyModeration, excerpt, postsInTab } from './queue'

const post = (id: number, approvalStatus: ModerationPost['approvalStatus']): ModerationPost => ({
  id,
  slug: `post-${id}`,
  title: `Post ${id}`,
  description: null,
  boardId: 1,
  approvalStatus,
  author: { id: 1, fullName: 'Ada', avatarUrl: 'https://example.com/a.png' },
  createdAt: '2026-10-28T10:00:00Z',
})

const queue: ModerationQueue = {
  posts: [post(1, 'pending'), post(2, 'pending'), post(3, 'rejected')],
  // More pending posts exist than the list holds
  pendingCount: 120,
  allowAnonymousFeedback: true,
  feedbackApprovalPolicy: 'always_require_approval',
}

describe('applyModeration', () => {
  it('removes approved posts and lowers the pending count', () => {
    const result = applyModeration(queue, 1, 'approved')
    expect(result.posts.map((p) => p.id)).toEqual([2, 3])
    expect(result.pendingCount).toBe(119)
  })

  it('moves rejected posts to the rejected tab', () => {
    const result = applyModeration(queue, 2, 'rejected')
    expect(postsInTab(result, 'pending').map((p) => p.id)).toEqual([1])
    expect(postsInTab(result, 'rejected').map((p) => p.id)).toEqual([2, 3])
    expect(result.pendingCount).toBe(119)
  })

  it('keeps the pending count when a rejected post is approved', () => {
    const result = applyModeration(queue, 3, 'approved')
    expect(result.posts.map((p) => p.id)).toEqual([1, 2])
    expect(result.pendingCount).toBe(120)
  })

  it('ignores posts that are not in the queue', () => {
    expect(applyModeration(queue, 99, 'approved')).toBe(queue)
  })
})

describe('excerpt', () => {
  it('strips Markdown marks and shortens long text', () => {
    expect(excerpt('## **Dark** mode\n\n- for [all](https://x.y) pages ![logo](a.png)')).toBe(
      'Dark mode for all pages logo',
    )
    expect(excerpt('Buy now! (really)')).toBe('Buy now! (really)')
    expect(excerpt('a'.repeat(250))).toHaveLength(201)
    expect(excerpt(null)).toBe('')
  })
})
