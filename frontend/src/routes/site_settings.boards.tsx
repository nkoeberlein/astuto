import { createFileRoute, redirect } from '@tanstack/react-router'
import { boardsQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { BoardsSettingsPage } from '@/features/site-settings/BoardsSettingsPage'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'
import { isAdmin } from '@/lib/roles'

export const Route = createFileRoute('/site_settings/boards')({
  loader: async ({ context: { queryClient }, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })
    // The list itself is public; editing is for admins
    if (!isAdmin(session.user)) throw redirect({ to: '/' })

    await queryClient.ensureQueryData(boardsQuery)
  },
  component: () => (
    <SiteSettingsLayout>
      <BoardsSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
