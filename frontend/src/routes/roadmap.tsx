import { createFileRoute, redirect } from '@tanstack/react-router'
import { useCallback } from 'react'
import { boardsQuery, roadmapQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { RoadmapPage } from '@/features/roadmap/RoadmapPage'
import {
  filtersFromRoadmapSearch,
  type RoadmapFilters,
  roadmapSearchFromFilters,
  validateRoadmapSearch,
} from '@/features/roadmap/search'

export const Route = createFileRoute('/roadmap')({
  validateSearch: validateRoadmapSearch,
  loaderDeps: ({ search }) => ({ sort: search.sort }),
  loader: async ({ context: { queryClient }, deps }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.tenant.settings.roadmapEnabled) throw redirect({ to: '/' })

    const { sortBy } = filtersFromRoadmapSearch(deps)
    await Promise.all([
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(roadmapQuery(sortBy)),
    ])
  },
  component: RoadmapRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function RoadmapRoute() {
  const filters = filtersFromRoadmapSearch(Route.useSearch())
  const navigate = Route.useNavigate()

  const onFiltersChange = useCallback(
    (changes: Partial<RoadmapFilters>) =>
      navigate({
        replace: true,
        search: (prev) =>
          roadmapSearchFromFilters({ ...filtersFromRoadmapSearch(prev), ...changes }),
      }),
    [navigate],
  )

  return <RoadmapPage filters={filters} onFiltersChange={onFiltersChange} />
}
