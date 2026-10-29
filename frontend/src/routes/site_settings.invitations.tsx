import { createFileRoute } from '@tanstack/react-router'
import { invitationsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { InvitationsSettingsPage } from '@/features/site-settings/InvitationsSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/invitations')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([queryClient.ensureQueryData(invitationsQuery)])
  },
  component: () => (
    <SiteSettingsLayout>
      <InvitationsSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
