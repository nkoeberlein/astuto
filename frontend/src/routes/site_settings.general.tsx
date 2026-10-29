import { createFileRoute, redirect } from '@tanstack/react-router'
import { boardsQuery, generalSettingsQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { GeneralSettingsPage } from '@/features/site-settings/GeneralSettingsPage'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/general')({
  loader: async ({ context: { queryClient }, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })

    // Non-admins get a 403 from the API, shown by the error view
    await Promise.all([
      queryClient.ensureQueryData(generalSettingsQuery),
      queryClient.ensureQueryData(boardsQuery),
    ])
  },
  component: () => (
    <SiteSettingsLayout>
      <GeneralSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
