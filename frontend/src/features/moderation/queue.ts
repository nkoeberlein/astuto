import type { ModerationQueue } from '@/api/client'

export type ModerationTab = 'pending' | 'rejected'

// The queue after a moderator's decision: approved posts leave it, rejected ones move tabs
export function applyModeration(
  queue: ModerationQueue,
  postId: number,
  approvalStatus: 'approved' | 'pending' | 'rejected',
): ModerationQueue {
  const before = queue.posts.find((post) => post.id === postId)
  if (!before) return queue

  const wasPending = before.approvalStatus === 'pending'
  const isPending = approvalStatus === 'pending'
  const posts =
    approvalStatus === 'approved'
      ? queue.posts.filter((post) => post.id !== postId)
      : queue.posts.map((post) => (post.id === postId ? { ...post, approvalStatus } : post))

  return {
    ...queue,
    posts,
    pendingCount: Math.max(0, queue.pendingCount + Number(isPending) - Number(wasPending)),
  }
}

export function postsInTab(queue: ModerationQueue, tab: ModerationTab) {
  return queue.posts.filter((post) => post.approvalStatus === tab)
}
