import { useSuspenseInfiniteQuery, useSuspenseQuery } from '@tanstack/react-query'
import type { Board } from '@/api/client'
import { boardPostsQuery, type PostFilters, postStatusesQuery, sessionQuery } from '@/api/queries'
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
  const posts = useSuspenseInfiniteQuery(boardPostsQuery(board.slug, filters))

  const statusById = new Map(statuses.map((status) => [status.id, status]))
  const items = posts.data.pages.flatMap((page) => page.posts)

  return (
    <div className="space-y-6">
      <div className="space-y-1">
        <h1 className="text-2xl font-semibold tracking-tight">{board.name}</h1>
        {board.description && (
          <div className="text-muted-foreground">
            <Markdown>{board.description}</Markdown>
          </div>
        )}
      </div>

      <NewPostForm board={board} session={session} />

      <BoardFilters filters={filters} statuses={statuses} onChange={onFiltersChange} />

      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed p-8 text-center text-muted-foreground">
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
  )
}
