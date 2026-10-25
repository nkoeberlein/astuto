import { Link } from '@tanstack/react-router'
import { ChevronUp, MessageSquare } from 'lucide-react'
import type { Board, RoadmapColumn as RoadmapColumnData, RoadmapPost } from '@/api/client'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'

type Props = {
  column: RoadmapColumnData & { hiddenCount: number }
  boardById: Map<number, Board>
  showBoard: boolean
  showVoteCount: boolean
}

// One status of the roadmap with its posts, top border in the status color
export function RoadmapColumn({ column, boardById, showBoard, showVoteCount }: Props) {
  const { t } = useI18n()
  const headingId = `roadmap-status-${column.status.id}`

  return (
    <section
      aria-labelledby={headingId}
      className="flex w-72 shrink-0 snap-start flex-col rounded-xl border border-t-4 bg-muted/40 shadow-2xs md:w-auto md:min-w-64 md:flex-1"
      style={{ borderTopColor: column.status.color }}
    >
      <header className="flex items-center justify-between gap-2 px-3 py-2.5">
        <h2 id={headingId} className="truncate text-sm font-semibold">
          {column.status.name}
        </h2>
        <span className="rounded-full bg-background px-2 py-0.5 text-xs text-muted-foreground tabular-nums">
          {column.postsCount}
        </span>
      </header>

      {column.posts.length === 0 ? (
        <p className="px-3 pb-4 text-center text-sm text-muted-foreground">
          {t('board.posts_list.empty')}
        </p>
      ) : (
        <ul className="space-y-2 px-2 pb-2">
          {column.posts.map((post) => (
            <RoadmapCard
              key={post.id}
              post={post}
              boardName={showBoard ? boardById.get(post.boardId)?.name : undefined}
              showVoteCount={showVoteCount}
            />
          ))}
        </ul>
      )}

      {column.hiddenCount > 0 && (
        <p className="px-3 pb-3 text-center text-xs text-muted-foreground">
          {t('roadmap.more_posts', { count: column.hiddenCount })}
        </p>
      )}
    </section>
  )
}

function RoadmapCard(props: {
  post: RoadmapPost
  boardName: string | undefined
  showVoteCount: boolean
}) {
  const { t } = useI18n()
  const { post } = props

  return (
    <li>
      <Link
        to="/posts/$postSlug"
        params={{ postSlug: post.slug }}
        className="block space-y-2 rounded-lg border bg-card p-3 text-sm shadow-2xs transition-all hover:border-primary/40 hover:shadow-md focus-visible:outline-2 focus-visible:outline-ring"
      >
        <span className="line-clamp-3 font-medium">{post.title}</span>
        <span className="flex items-center gap-3 text-xs text-muted-foreground">
          {props.boardName && (
            <span className="min-w-0 flex-1 truncate uppercase tracking-wide">
              {props.boardName}
            </span>
          )}
          <span className="ml-auto flex items-center gap-3">
            {props.showVoteCount && (
              <span
                className={cn('flex items-center gap-0.5', post.liked && 'text-primary')}
                title={t('post.likes_box.title')}
              >
                <ChevronUp className="size-3.5" aria-hidden /> {post.likesCount}
              </span>
            )}
            <span className="flex items-center gap-1" title={t('post.comments.title')}>
              <MessageSquare className="size-3.5" aria-hidden /> {post.commentsCount}
            </span>
          </span>
        </span>
      </Link>
    </li>
  )
}
