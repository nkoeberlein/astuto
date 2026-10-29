import { createFileRoute } from '@tanstack/react-router'
import { useCallback } from 'react'
import { boardsQuery, roadmapQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { RoadmapPage } from '@/features/roadmap/RoadmapPage'
import {
  type EmbeddedRoadmapSearch,
  filtersFromRoadmapSearch,
  type RoadmapFilters,
  roadmapSearchFromFilters,
  scopeFromEmbeddedSearch,
  validateEmbeddedRoadmapSearch,
} from '@/features/roadmap/search'
import { useI18n } from '@/lib/i18n'

// Roadmap for an iframe on another site (legacy: /embedded_roadmap). The root layout leaves out
// header and footer; SpaController allows framing only for this page.
export const Route = createFileRoute('/embedded_roadmap')({
  staticData: { embedded: true },
  validateSearch: validateEmbeddedRoadmapSearch,
  loaderDeps: ({ search }) => ({ sort: search.sort }),
  loader: async ({ context: { queryClient }, deps }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    // No redirect: the home page has no place in someone else's iframe
    if (!session.tenant.settings.roadmapEnabled) return { enabled: false }

    const { sortBy } = filtersFromRoadmapSearch(deps)
    await Promise.all([
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(roadmapQuery(sortBy)),
    ])
    return { enabled: true }
  },
  component: EmbeddedRoadmapRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function EmbeddedRoadmapRoute() {
  const { t } = useI18n()
  const { enabled } = Route.useLoaderData()
  const search = Route.useSearch()
  const navigate = Route.useNavigate()

  const onFiltersChange = useCallback(
    (changes: Partial<RoadmapFilters>) =>
      navigate({
        replace: true,
        // The scope params (show_*) belong to the embedding site and stay as they are
        search: (prev: EmbeddedRoadmapSearch) => ({
          ...prev,
          ...roadmapSearchFromFilters({ ...filtersFromRoadmapSearch(prev), ...changes }),
        }),
      }),
    [navigate],
  )

  if (!enabled) {
    return <p className="p-8 text-center text-muted-foreground">{t('roadmap.empty')}</p>
  }

  return (
    <RoadmapPage
      filters={filtersFromRoadmapSearch(search)}
      onFiltersChange={onFiltersChange}
      embed={scopeFromEmbeddedSearch(search)}
    />
  )
}
