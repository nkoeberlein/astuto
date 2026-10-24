import type { Comment } from '@/api/client'
import { Markdown } from '@/components/Markdown'
import { UserAvatar } from '@/components/UserAvatar'
import { Badge } from '@/components/ui/badge'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'

// Top-level comments with their replies (one level deep, like the legacy UI)
export function groupComments(comments: Comment[]) {
  const replies = new Map<number, Comment[]>()
  for (const comment of comments) {
    if (comment.parentId === null) continue
    replies.set(comment.parentId, [...(replies.get(comment.parentId) ?? []), comment])
  }
  return comments
    .filter((comment) => comment.parentId === null)
    .map((comment) => ({ comment, replies: replies.get(comment.id) ?? [] }))
}

function CommentItem({ comment }: { comment: Comment }) {
  const { t, locale } = useI18n()
  const name = comment.author?.fullName ?? t('post.published_anonymously')

  return (
    <div className="flex gap-3">
      <UserAvatar name={name} url={comment.author?.avatarUrl ?? ''} />
      <div className="min-w-0 flex-1 space-y-1">
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <span className="font-medium">{name}</span>
          {comment.isPostUpdate && <Badge>{t('post.comments.post_update_badge')}</Badge>}
          <time className="text-xs text-muted-foreground" dateTime={comment.createdAt}>
            {formatRelativeTime(comment.createdAt, locale)}
          </time>
        </div>
        <Markdown>{comment.body}</Markdown>
      </div>
    </div>
  )
}

export function CommentList({ comments }: { comments: Comment[] }) {
  const { t } = useI18n()
  if (comments.length === 0) {
    return <p className="text-sm text-muted-foreground">{t('post.comments.empty')}</p>
  }
  return (
    <ul className="space-y-6">
      {groupComments(comments).map(({ comment, replies }) => (
        <li key={comment.id} className="space-y-4">
          <CommentItem comment={comment} />
          {replies.length > 0 && (
            <ul className="ml-10 space-y-4 border-l pl-4">
              {replies.map((reply) => (
                <li key={reply.id}>
                  <CommentItem comment={reply} />
                </li>
              ))}
            </ul>
          )}
        </li>
      ))}
    </ul>
  )
}
