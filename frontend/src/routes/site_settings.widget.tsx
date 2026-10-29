import { createFileRoute } from '@tanstack/react-router'
import { widgetSettingsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'
import { WidgetSettingsPage } from '@/features/site-settings/WidgetSettingsPage'

export const Route = createFileRoute('/site_settings/widget')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await queryClient.ensureQueryData(widgetSettingsQuery)
  },
  component: () => (
    <SiteSettingsLayout>
      <WidgetSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
