import { createFileRoute, redirect } from '@tanstack/react-router'
import { profileQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { ProfilePage } from '@/features/profile/ProfilePage'

export const Route = createFileRoute('/profile')({
  loader: async ({ context: { queryClient }, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })
    await queryClient.ensureQueryData(profileQuery)
  },
  component: ProfilePage,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
