import { createFileRoute } from '@tanstack/react-router'
import { auditEventsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { AuditLogPage } from '@/features/site-settings/AuditLogPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/audit_log')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await queryClient.ensureInfiniteQueryData(auditEventsQuery(null))
  },
  component: () => (
    <SiteSettingsLayout>
      <AuditLogPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
