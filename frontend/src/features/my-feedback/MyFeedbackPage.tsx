import { useSuspenseInfiniteQuery, useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import type { MyPost } from '@/api/client'
import {
  MY_POSTS_FILTERS,
  type MyPostsFilter,
  myPostsQuery,
  postStatusesQuery,
  sessionQuery,
} from '@/api/queries'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { PostListItem } from '@/features/boards/PostListItem'
import { useI18n } from '@/lib/i18n'

const linkClass =
  'rounded-lg px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-foreground'
const activeClass = 'bg-primary/10 font-semibold text-primary ring-1 ring-primary/20'

// Posts the signed-in person created, voted on or follows (#429)
export function MyFeedbackPage({ filter }: { filter: MyPostsFilter }) {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const posts = useSuspenseInfiniteQuery(myPostsQuery(filter))

  const statusById = new Map(statuses.map((status) => [status.id, status]))
  const items = posts.data.pages.flatMap((page) => page.posts)
  const counts = posts.data.pages[0]?.counts

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold tracking-tight">{t('my_feedback.title')}</h1>
        <nav className="flex flex-wrap gap-1" aria-label={t('my_feedback.title')}>
          {MY_POSTS_FILTERS.map((option) => (
            <Link
              key={option}
              to="/my-feedback"
              search={{ filter: option === 'created' ? undefined : option }}
              className={option === filter ? `${linkClass} ${activeClass}` : linkClass}
              aria-current={option === filter ? 'page' : undefined}
            >
              {t(`my_feedback.filters.${option}`)}
              {counts && <span className="ms-1.5 text-xs opacity-70">{counts[option]}</span>}
            </Link>
          ))}
        </nav>
      </div>

      {items.length === 0 ? (
        <p className="rounded-xl border border-dashed p-10 text-center text-muted-foreground">
          {t(`my_feedback.empty.${filter}`)}
        </p>
      ) : (
        <ul className="space-y-3">
          {items.map((post) => (
            <PostListItem
              key={post.id}
              post={post}
              status={post.postStatusId ? statusById.get(post.postStatusId) : undefined}
              showVoteCount={session.tenant.settings.showVoteCount}
              voteButton={false}
              signedIn
              meta={<PostMeta post={post} />}
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

function PostMeta({ post }: { post: MyPost }) {
  const { t } = useI18n()
  return (
    <>
      {post.board && <span>{post.board.name}</span>}
      {post.approvalStatus !== 'approved' && (
        <Badge variant="outline">{t(`my_feedback.approval.${post.approvalStatus}`)}</Badge>
      )}
    </>
  )
}
