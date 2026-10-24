import { useSuspenseQuery } from '@tanstack/react-query'
import { createFileRoute } from '@tanstack/react-router'
import { useCallback } from 'react'
import type { Board } from '@/api/client'
import { boardPostsQuery, boardsQuery, type PostFilters, postStatusesQuery } from '@/api/queries'
import { BoardPage } from '@/features/boards/BoardPage'
import { filtersFromSearch, validateBoardSearch } from '@/features/boards/search'
import { ErrorView } from '@/features/layout/ErrorView'
import { useI18n } from '@/lib/i18n'

export const Route = createFileRoute('/boards/$boardSlug')({
  validateSearch: validateBoardSearch,
  loaderDeps: ({ search }) => filtersFromSearch(search),
  loader: async ({ context: { queryClient }, params, deps }) => {
    await Promise.all([
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(postStatusesQuery),
      queryClient.ensureInfiniteQueryData(boardPostsQuery(params.boardSlug, deps)),
    ])
  },
  component: BoardRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function BoardRoute() {
  const { t } = useI18n()
  const { boardSlug } = Route.useParams()
  const filters = filtersFromSearch(Route.useSearch())
  const navigate = Route.useNavigate()
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const board: Board | undefined = boards.find((b) => b.slug === boardSlug)

  const onFiltersChange = useCallback(
    (changes: Partial<PostFilters>) =>
      navigate({
        replace: true,
        search: (prev) => {
          const next = { ...filtersFromSearch(prev), ...changes }
          return {
            q: next.search || undefined,
            sort: next.sortBy === 'trending' ? undefined : next.sortBy,
            status: next.statusIds.length ? next.statusIds.join(',') : undefined,
          }
        },
      }),
    [navigate],
  )

  if (!board) return <p className="text-center">{t('common.errors.not_found')}</p>
  return <BoardPage board={board} filters={filters} onFiltersChange={onFiltersChange} />
}
