import { useSuspenseInfiniteQuery, useSuspenseQuery } from '@tanstack/react-query'
import { Lock, Rss } from 'lucide-react'
import type { Board } from '@/api/client'
import {
  boardPostsQuery,
  boardStatusesQuery,
  type PostFilters,
  postStatusesQuery,
  sessionQuery,
} from '@/api/queries'
import { Markdown } from '@/components/Markdown'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'
import { BoardFilters } from './BoardFilters'
import { NewPostForm } from './NewPostForm'
import { PostListItem } from './PostListItem'

type Props = {
  board: Board
  filters: PostFilters
  onFiltersChange: (changes: Partial<PostFilters>) => void
}

export function BoardPage({ board, filters, onFiltersChange }: Props) {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const { data: filterStatuses } = useSuspenseQuery(
    boardStatusesQuery(board.slug, session.tenant.settings.hideUnusedStatusesInFilterByStatus),
  )
  const posts = useSuspenseInfiniteQuery(boardPostsQuery(board.slug, filters))

  const statusById = new Map(statuses.map((status) => [status.id, status]))
  const items = posts.data.pages.flatMap((page) => page.posts)

  return (
    <div className="grid gap-6 lg:grid-cols-[360px_minmax(0,1fr)] lg:items-start lg:gap-8 xl:grid-cols-[400px_minmax(0,1fr)]">
      <aside className="space-y-5 lg:sticky lg:top-20">
        <div className="space-y-1.5 rounded-xl border border-primary/15 bg-linear-to-r from-primary/5 via-card to-card p-5 shadow-2xs">
          <h1 className="text-2xl font-bold tracking-tight">{board.name}</h1>
          {board.visibility !== 'everyone' && (
            <p className="inline-flex items-center gap-1 text-xs text-muted-foreground">
              <Lock className="size-3" aria-hidden />
              {t(`site_settings.boards.visibility.${board.visibility}`)}
            </p>
          )}
          {board.description && (
            <div className="text-sm text-muted-foreground">
              <Markdown>{board.description}</Markdown>
            </div>
          )}
          {!session.tenant.settings.isPrivate && board.visibility === 'everyone' && (
            <a
              href={`/boards/${encodeURIComponent(board.slug)}/feed`}
              className="inline-flex items-center gap-1 pt-1 text-xs text-muted-foreground hover:text-foreground"
            >
              <Rss className="size-3" aria-hidden />
              {t('board.rss_feed')}
            </a>
          )}
        </div>

        <NewPostForm board={board} session={session} />

        <BoardFilters filters={filters} statuses={filterStatuses} onChange={onFiltersChange} />
      </aside>

      <div className="min-w-0 space-y-4">
        {items.length === 0 ? (
          <p className="rounded-xl border border-dashed p-10 text-center text-muted-foreground">
            {t('board.posts_list.empty')}
          </p>
        ) : (
          <ul className="space-y-3">
            {items.map((post) => (
              <PostListItem
                key={post.id}
                post={post}
                status={post.postStatusId ? statusById.get(post.postStatusId) : undefined}
                showVoteCount={session.tenant.settings.showVoteCount}
                voteButton={session.tenant.settings.showVoteButtonInBoard}
                signedIn={session.user !== null}
              />
            ))}
          </ul>
        )}

        {posts.hasNextPage && (
          <div className="flex justify-center">
            <Button
              variant="outline"
              onClick={() => posts.fetchNextPage()}
              disabled={posts.isFetchingNextPage}
            >
              {t('board.posts_list.load_more')}
            </Button>
          </div>
        )}
      </div>
    </div>
  )
}
