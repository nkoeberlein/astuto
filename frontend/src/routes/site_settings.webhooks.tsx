import { createFileRoute } from '@tanstack/react-router'
import { webhooksQuery, webhookVariablesQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'
import { WebhooksSettingsPage } from '@/features/site-settings/WebhooksSettingsPage'

export const Route = createFileRoute('/site_settings/webhooks')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([
      queryClient.ensureQueryData(webhooksQuery),
      queryClient.ensureQueryData(webhookVariablesQuery),
    ])
  },
  component: () => (
    <SiteSettingsLayout>
      <WebhooksSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
