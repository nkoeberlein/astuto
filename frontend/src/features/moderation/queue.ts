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

// Plain text for the list: Markdown syntax removed, cut after `max` characters
export function excerpt(markdown: string | null, max = 200): string {
  const text = (markdown ?? '')
    // Links and images keep only their text
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
    // Headings, quotes and list markers at the start of a line
    .replace(/^\s{0,3}(#{1,6}|>|[-*+]|\d+\.)\s+/gm, '')
    .replace(/[*_`~]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  return text.length > max ? `${text.slice(0, max).trimEnd()}…` : text
}
