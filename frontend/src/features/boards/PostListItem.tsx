import { Link } from '@tanstack/react-router'
import { MessageSquare } from 'lucide-react'
import type { PostListItem as PostListItemData, PostStatus } from '@/api/client'
import { StatusBadge } from '@/features/posts/StatusBadge'
import { VoteButton } from '@/features/posts/VoteButton'
import { VoteCount } from '@/features/posts/VoteCount'
import { useI18n } from '@/lib/i18n'

// Plain-text preview of a Markdown description
export function excerpt(markdown: string | null, length = 180): string {
  const text = (markdown ?? '')
    .replace(/[#*_>`~[\]()!]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  return text.length > length ? `${text.slice(0, length).trimEnd()}…` : text
}

export function PostListItem(props: {
  post: PostListItemData
  status: PostStatus | undefined
  showVoteCount: boolean
  voteButton: boolean
  signedIn: boolean
}) {
  const { t } = useI18n()
  const { post } = props

  return (
    <li className="flex gap-4 rounded-lg border bg-card p-4 transition-colors hover:border-primary/40">
      {props.showVoteCount &&
        (props.voteButton ? (
          <VoteButton post={post} signedIn={props.signedIn} />
        ) : (
          <VoteCount count={post.likesCount} liked={post.liked} label={t('post.likes_box.title')} />
        ))}
      <div className="min-w-0 flex-1 space-y-1">
        <Link
          to="/posts/$postSlug"
          params={{ postSlug: post.slug }}
          className="font-medium hover:underline"
        >
          {post.title}
        </Link>
        {post.description && (
          <p className="line-clamp-2 text-sm text-muted-foreground">{excerpt(post.description)}</p>
        )}
        <div className="flex items-center gap-3 pt-1 text-xs text-muted-foreground">
          <StatusBadge status={props.status} />
          <span className="flex items-center gap-1" title={t('post.comments.title')}>
            <MessageSquare className="size-3.5" aria-hidden /> {post.commentsCount}
          </span>
        </div>
      </div>
    </li>
  )
}
