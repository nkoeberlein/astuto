import { useInfiniteQuery, useSuspenseQuery } from '@tanstack/react-query'
import { ExternalLink, X } from 'lucide-react'
import { Suspense, useEffect, useRef, useState } from 'react'
import { useWidgetSignIn, useWidgetSignOut } from '@/api/mutations'
import {
  boardPostsQuery,
  boardsQuery,
  postStatusesQuery,
  type RoadmapSortBy,
  sessionQuery,
} from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { NewPostForm } from '@/features/boards/NewPostForm'
import { PostListItem } from '@/features/boards/PostListItem'
import { ChangelogPage } from '@/features/changelog/ChangelogPage'
import { RoadmapPage } from '@/features/roadmap/RoadmapPage'
import { useI18n } from '@/lib/i18n'

type Tab = 'feedback' | 'roadmap' | 'changelog'

// Messages from widget.js on the embedding page: astuto:identify { token } signs the visitor
// in, astuto:logout signs out. Only the parent window is listened to.
function useParentMessages() {
  const signIn = useWidgetSignIn()
  const signOut = useWidgetSignOut()
  // The listener is registered once and calls the latest handlers
  const handlers = useRef({ signIn: signIn.mutate, signOut })
  handlers.current = { signIn: signIn.mutate, signOut }

  useEffect(() => {
    if (window.parent === window) return
    const onMessage = (event: MessageEvent) => {
      if (event.source !== window.parent) return
      const data = event.data as { type?: unknown; token?: unknown } | null
      if (data?.type === 'astuto:identify' && typeof data.token === 'string')
        handlers.current.signIn(data.token)
      if (data?.type === 'astuto:logout') handlers.current.signOut()
    }
    window.addEventListener('message', onMessage)
    // Nothing secret: tells widget.js that it can send the token now
    window.parent.postMessage({ type: 'astuto:ready' }, '*')
    return () => window.removeEventListener('message', onMessage)
  }, [])

  return signIn
}

// Content of the feedback widget (public/widget.js shows it in an iframe on other sites)
export function EmbedPage() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const signIn = useParentMessages()
  const [tab, setTab] = useState<Tab>('feedback')
  const tabs: Tab[] = [
    'feedback',
    ...(session.tenant.settings.roadmapEnabled ? (['roadmap'] as const) : []),
    ...(session.tenant.hasChangelog ? (['changelog'] as const) : []),
  ]

  return (
    <div className="flex min-h-dvh flex-col gap-4 p-4">
      <div className="flex items-center justify-between gap-2">
        <nav className="flex gap-1" aria-label={session.tenant.siteName}>
          {tabs.map((option) => (
            <button
              key={option}
              type="button"
              aria-current={option === tab ? 'page' : undefined}
              onClick={() => setTab(option)}
              className={
                option === tab
                  ? 'rounded-lg bg-primary/10 px-3 py-1.5 text-sm font-semibold text-primary ring-1 ring-primary/20'
                  : 'rounded-lg px-3 py-1.5 text-sm text-muted-foreground hover:bg-accent hover:text-foreground'
              }
            >
              {t(`widget.tabs.${option}`)}
            </button>
          ))}
        </nav>
        {window.parent !== window && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="size-8 p-0"
            aria-label={t('widget.close')}
            onClick={() => window.parent.postMessage({ type: 'astuto:close' }, '*')}
          >
            <X className="size-4" aria-hidden />
          </Button>
        )}
      </div>

      {session.user && (
        <p className="text-xs text-muted-foreground">
          {t('widget.signed_in_as', { name: session.user.fullName })}
        </p>
      )}
      <FormError error={signIn.error} />

      <Suspense fallback={<p className="text-sm text-muted-foreground">…</p>}>
        {tab === 'feedback' && <FeedbackTab />}
        {tab === 'roadmap' && <RoadmapTab />}
        {tab === 'changelog' && <ChangelogPage />}
      </Suspense>

      <a
        href="/"
        target="_blank"
        rel="noopener"
        className="mt-auto inline-flex items-center gap-1 self-center text-xs text-muted-foreground hover:text-foreground"
      >
        {t('widget.open_site')}
        <ExternalLink className="size-3" aria-hidden />
      </a>
    </div>
  )
}

function FeedbackTab() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const [boardId, setBoardId] = useState(boards[0]?.id)
  const board = boards.find((candidate) => candidate.id === boardId) ?? boards[0]
  const posts = useInfiniteQuery({
    ...boardPostsQuery(board?.slug ?? '', {
      search: '',
      sortBy: session.tenant.settings.defaultPostSorting,
      statusIds: [],
    }),
    enabled: Boolean(board),
  })
  if (!board) return <p className="text-sm text-muted-foreground">{t('board.posts_list.empty')}</p>

  const statusById = new Map(statuses.map((status) => [status.id, status]))
  const items = posts.data?.pages.flatMap((page) => page.posts) ?? []

  return (
    <div className="space-y-4">
      {boards.length > 1 && (
        <Select value={String(board.id)} onValueChange={(value) => setBoardId(Number(value))}>
          <SelectTrigger aria-label={t('widget.board')} className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {boards.map((candidate) => (
              <SelectItem key={candidate.id} value={String(candidate.id)}>
                {candidate.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      )}
      <NewPostForm board={board} session={session} />
      <ul className="space-y-3">
        {items.map((post) => (
          <PostListItem
            key={post.id}
            post={post}
            status={post.postStatusId ? statusById.get(post.postStatusId) : undefined}
            showVoteCount={session.tenant.settings.showVoteCount}
            voteButton={session.tenant.settings.showVoteButtonInBoard}
            signedIn={session.user !== null}
            newTab
          />
        ))}
      </ul>
      {posts.hasNextPage && (
        <div className="flex justify-center">
          <Button
            variant="outline"
            size="sm"
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

function RoadmapTab() {
  const [sortBy, setSortBy] = useState<RoadmapSortBy>('most_voted')
  const [boardIds, setBoardIds] = useState<number[]>([])
  const [statusIds, setStatusIds] = useState<number[]>([])
  return (
    <RoadmapPage
      filters={{ boardIds, statusIds, sortBy }}
      onFiltersChange={(changes) => {
        if (changes.sortBy) setSortBy(changes.sortBy)
        if (changes.boardIds) setBoardIds(changes.boardIds)
        if (changes.statusIds) setStatusIds(changes.statusIds)
      }}
      embed={{ boardIds: [], statusIds: [], showBoardFilter: true, showStatusFilter: false }}
    />
  )
}
