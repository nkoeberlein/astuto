import { createFileRoute } from '@tanstack/react-router'
import { generalSettingsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { AppearanceSettingsPage } from '@/features/site-settings/AppearanceSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/appearance')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([queryClient.ensureQueryData(generalSettingsQuery)])
  },
  component: () => (
    <SiteSettingsLayout>
      <AppearanceSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
