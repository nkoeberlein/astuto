import { createFileRoute } from '@tanstack/react-router'
import { generalSettingsQuery, oAuthSettingsQuery, samlSettingsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { AuthenticationSettingsPage } from '@/features/site-settings/AuthenticationSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/authentication')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([
      queryClient.ensureQueryData(generalSettingsQuery),
      queryClient.ensureQueryData(oAuthSettingsQuery),
      queryClient.ensureQueryData(samlSettingsQuery),
    ])
  },
  component: () => (
    <SiteSettingsLayout>
      <AuthenticationSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
