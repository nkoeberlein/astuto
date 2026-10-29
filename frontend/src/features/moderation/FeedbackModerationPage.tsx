import { useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { Check, Settings, X } from 'lucide-react'
import type { ReactNode } from 'react'
import type { Board, ModerationPost } from '@/api/client'
import { useModeratePost } from '@/api/mutations'
import { boardsQuery, moderationPostsQuery, sessionQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { UserAvatar } from '@/components/UserAvatar'
import { Button } from '@/components/ui/button'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { excerpt } from '@/lib/text'
import { cn } from '@/lib/utils'
import { ModerationNav } from './ModerationNav'
import { type ModerationTab, postsInTab } from './queue'

// Feedback queue (legacy: /moderation/feedback): approve or reject posts waiting for approval
export function FeedbackModerationPage({ tab }: { tab: ModerationTab }) {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: queue } = useSuspenseQuery(moderationPostsQuery)
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const moderate = useModeratePost()

  const boardById = new Map(boards.map((board) => [board.id, board]))
  const posts = postsInTab(queue, tab)
  const isAdmin = session.user?.role === 'admin' || session.user?.role === 'owner'

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="space-y-3">
        <ModerationNav />
        {isAdmin && (
          <div className="flex flex-wrap items-center gap-2 text-xs">
            <span className="rounded-full border px-2.5 py-1 text-muted-foreground">
              {queue.allowAnonymousFeedback
                ? t('moderation.feedback.anonymous_feedback_allowed')
                : t('moderation.feedback.anonymous_feedback_not_allowed')}
            </span>
            <span className="rounded-full border px-2.5 py-1 text-muted-foreground">
              {t(`site_settings.general.feedback_approval_policy_${queue.feedbackApprovalPolicy}`)}
            </span>
            <Link
              to="/site_settings/general"
              className="flex items-center gap-1 text-primary underline-offset-4 hover:underline"
            >
              <Settings className="size-3.5" aria-hidden />
              {t('moderation.feedback.change_feedback_moderation_settings')}
            </Link>
          </div>
        )}
      </div>

      <nav className="flex gap-1 border-b" aria-label={t('moderation.menu.feedback')}>
        <TabLink tab="pending" active={tab === 'pending'}>
          {t('activerecord.attributes.post.approval_status_pending')}
          <span className="rounded-full bg-muted px-2 py-0.5 text-xs tabular-nums">
            {queue.pendingCount}
          </span>
        </TabLink>
        <TabLink tab="rejected" active={tab === 'rejected'}>
          {t('activerecord.attributes.post.approval_status_rejected')}
        </TabLink>
      </nav>

      <FormError error={moderate.error} />

      {posts.length === 0 ? (
        <p className="rounded-lg border border-dashed p-8 text-center text-muted-foreground">
          {t('board.posts_list.empty')}
        </p>
      ) : (
        <ul className="space-y-3">
          {posts.map((post) => (
            <QueueItem
              key={post.id}
              post={post}
              board={boardById.get(post.boardId)}
              busy={moderate.isPending && moderate.variables?.id === post.id}
              onApprove={() => moderate.mutate({ id: post.id, approvalStatus: 'approved' })}
              onReject={
                post.approvalStatus === 'pending'
                  ? () => moderate.mutate({ id: post.id, approvalStatus: 'rejected' })
                  : undefined
              }
            />
          ))}
        </ul>
      )}
    </div>
  )
}

function TabLink(props: { tab: ModerationTab; active: boolean; children: ReactNode }) {
  return (
    <Link
      to="/moderation/feedback"
      search={{ tab: props.tab === 'pending' ? undefined : props.tab }}
      replace
      aria-current={props.active ? 'page' : undefined}
      className={cn(
        '-mb-px flex items-center gap-2 border-b-2 px-3 py-2 text-sm',
        props.active
          ? 'border-primary font-semibold text-foreground'
          : 'border-transparent text-muted-foreground hover:text-foreground',
      )}
    >
      {props.children}
    </Link>
  )
}

function QueueItem(props: {
  post: ModerationPost
  board: Board | undefined
  busy: boolean
  onApprove: () => void
  onReject: (() => void) | undefined
}) {
  const { t, locale } = useI18n()
  const { post } = props
  // The schema cannot mark a $ref as nullable: anonymous posts have no author
  const author = post.author as ModerationPost['author'] | null
  const text = excerpt(post.description)

  return (
    <li className="flex flex-col gap-3 rounded-xl border bg-card p-4 shadow-2xs sm:flex-row sm:items-start">
      <div className="flex min-w-0 flex-1 gap-3">
        {author ? (
          <UserAvatar name={author.fullName} url={author.avatarUrl} className="size-9" />
        ) : (
          <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-muted text-xs text-muted-foreground">
            ?
          </span>
        )}
        <div className="min-w-0 space-y-1">
          <Link
            to="/posts/$postSlug"
            params={{ postSlug: post.slug }}
            className="font-medium underline-offset-4 hover:underline"
          >
            {post.title}
          </Link>
          {text && <p className="break-words text-sm text-muted-foreground">{text}</p>}
          <p className="flex flex-wrap gap-x-2 text-xs text-muted-foreground">
            <span>{author ? author.fullName : t('post.published_anonymously')}</span>
            {props.board && <span>· {props.board.name}</span>}
            <time dateTime={post.createdAt}>· {formatRelativeTime(post.createdAt, locale)}</time>
          </p>
        </div>
      </div>
      <div className="flex shrink-0 gap-2 sm:flex-col">
        <Button type="button" size="sm" disabled={props.busy} onClick={props.onApprove}>
          <Check className="size-4" aria-hidden />
          {t('common.buttons.approve')}
        </Button>
        {props.onReject && (
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={props.busy}
            onClick={props.onReject}
          >
            <X className="size-4" aria-hidden />
            {t('common.buttons.reject')}
          </Button>
        )}
      </div>
    </li>
  )
}
