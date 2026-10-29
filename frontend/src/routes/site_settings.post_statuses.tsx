import { createFileRoute, redirect } from '@tanstack/react-router'
import { postStatusesQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { PostStatusesSettingsPage } from '@/features/site-settings/PostStatusesSettingsPage'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'
import { isAdmin } from '@/lib/roles'

export const Route = createFileRoute('/site_settings/post_statuses')({
  loader: async ({ context: { queryClient }, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })
    // The list itself is public; editing is for admins
    if (!isAdmin(session.user)) throw redirect({ to: '/' })

    await queryClient.ensureQueryData(postStatusesQuery)
  },
  component: () => (
    <SiteSettingsLayout>
      <PostStatusesSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
