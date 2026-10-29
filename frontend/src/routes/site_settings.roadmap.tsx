import { createFileRoute } from '@tanstack/react-router'
import { boardsQuery, postStatusesQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { RoadmapSettingsPage } from '@/features/site-settings/RoadmapSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/roadmap')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(postStatusesQuery),
    ])
  },
  component: () => (
    <SiteSettingsLayout>
      <RoadmapSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
