import { useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { ArrowLeft } from 'lucide-react'
import {
  boardsQuery,
  commentsQuery,
  postQuery,
  postStatusesQuery,
  sessionQuery,
} from '@/api/queries'
import { Markdown } from '@/components/Markdown'
import { UserAvatar } from '@/components/UserAvatar'
import { Separator } from '@/components/ui/separator'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { CommentForm } from './CommentForm'
import { CommentList } from './CommentList'
import { FollowButton } from './FollowButton'
import { StatusBadge } from './StatusBadge'
import { VoteButton } from './VoteButton'

export function PostPage({ postSlug }: { postSlug: string }) {
  const { t, locale } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: post } = useSuspenseQuery(postQuery(postSlug))
  const { data: comments } = useSuspenseQuery(commentsQuery(postSlug))
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const { data: boards } = useSuspenseQuery(boardsQuery)

  const user = session.user
  const board = boards.find((b) => b.id === post.boardId)
  const status = statuses.find((s) => s.id === post.postStatusId)

  return (
    <article className="space-y-6">
      {board && (
        <Link
          to="/boards/$boardSlug"
          params={{ boardSlug: board.slug }}
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" aria-hidden /> {board.name}
        </Link>
      )}

      <header className="flex gap-4">
        {session.tenant.settings.showVoteCount && (
          <VoteButton post={post} signedIn={user !== null} />
        )}
        <div className="min-w-0 flex-1 space-y-2">
          <h1 className="text-2xl font-semibold tracking-tight">{post.title}</h1>
          <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
            <StatusBadge status={status} />
            {post.author ? (
              <span className="flex items-center gap-2">
                <UserAvatar
                  name={post.author.fullName}
                  url={post.author.avatarUrl}
                  className="size-5"
                />
                {t('post.published_by')} {post.author.fullName}
              </span>
            ) : (
              <span>{t('post.published_anonymously')}</span>
            )}
            <time dateTime={post.createdAt}>{formatRelativeTime(post.createdAt, locale)}</time>
          </div>
        </div>
      </header>

      {post.description && <Markdown>{post.description}</Markdown>}

      {user && <FollowButton postSlug={post.slug} followed={post.followed} />}

      <Separator />

      <section className="space-y-4" aria-labelledby="comments-title">
        <h2 id="comments-title" className="text-lg font-semibold">
          {t('post.comments.title')}
        </h2>
        <CommentList comments={comments} postSlug={user ? post.slug : undefined} />
        {user ? (
          <CommentForm
            postSlug={post.slug}
            canMarkAsUpdate={['moderator', 'admin', 'owner'].includes(user.role)}
          />
        ) : (
          <p className="text-sm text-muted-foreground">
            <a href="/users/sign_in" className="text-primary underline">
              {t('post.new_comment.not_logged_in')}
            </a>
          </p>
        )}
      </section>
    </article>
  )
}
