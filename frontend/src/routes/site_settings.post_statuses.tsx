import { createFileRoute } from '@tanstack/react-router'
import { postStatusesQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { PostStatusesSettingsPage } from '@/features/site-settings/PostStatusesSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/post_statuses')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([queryClient.ensureQueryData(postStatusesQuery)])
  },
  component: () => (
    <SiteSettingsLayout>
      <PostStatusesSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
