import { useSuspenseQuery } from '@tanstack/react-query'
import { createFileRoute } from '@tanstack/react-router'
import { useCallback } from 'react'
import type { Board } from '@/api/client'
import {
  boardPostsQuery,
  boardsQuery,
  type PostFilters,
  postStatusesQuery,
  sessionQuery,
} from '@/api/queries'
import { BoardPage } from '@/features/boards/BoardPage'
import { filtersFromSearch, validateBoardSearch } from '@/features/boards/search'
import { ErrorView } from '@/features/layout/ErrorView'
import { useI18n } from '@/lib/i18n'

export const Route = createFileRoute('/boards/$boardSlug')({
  validateSearch: validateBoardSearch,
  loaderDeps: ({ search }) => validateBoardSearch(search),
  loader: async ({ context: { queryClient }, params, deps }) => {
    // The tenant's default sorting applies when the URL has no ?sort= param
    const session = await queryClient.ensureQueryData(sessionQuery)
    const filters = filtersFromSearch(deps, session.tenant.settings.defaultPostSorting)
    await Promise.all([
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(postStatusesQuery),
      queryClient.ensureInfiniteQueryData(boardPostsQuery(params.boardSlug, filters)),
    ])
  },
  component: BoardRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function BoardRoute() {
  const { t } = useI18n()
  const { boardSlug } = Route.useParams()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const defaultSort = session.tenant.settings.defaultPostSorting
  const filters = filtersFromSearch(Route.useSearch(), defaultSort)
  const navigate = Route.useNavigate()
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const board: Board | undefined = boards.find((b) => b.slug === boardSlug)

  const onFiltersChange = useCallback(
    (changes: Partial<PostFilters>) =>
      navigate({
        replace: true,
        search: (prev) => {
          const next = { ...filtersFromSearch(prev, defaultSort), ...changes }
          return {
            q: next.search || undefined,
            sort: next.sortBy === defaultSort ? undefined : next.sortBy,
            status: next.statusIds.length ? next.statusIds.join(',') : undefined,
          }
        },
      }),
    [navigate, defaultSort],
  )

  if (!board) return <p className="text-center">{t('common.errors.not_found')}</p>
  return <BoardPage board={board} filters={filters} onFiltersChange={onFiltersChange} />
}
