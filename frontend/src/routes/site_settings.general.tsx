import { createFileRoute } from '@tanstack/react-router'
import { boardsQuery, generalSettingsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { GeneralSettingsPage } from '@/features/site-settings/GeneralSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/general')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(generalSettingsQuery),
    ])
  },
  component: () => (
    <SiteSettingsLayout>
      <GeneralSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
