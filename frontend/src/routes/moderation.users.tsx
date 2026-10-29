import { createFileRoute, redirect } from '@tanstack/react-router'
import { useCallback } from 'react'
import { moderationUsersQuery, sessionQuery, type UserFilters } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { UsersModerationPage } from '@/features/moderation/UsersModerationPage'
import {
  filtersFromUsersSearch,
  usersSearchFromFilters,
  validateUsersSearch,
} from '@/features/moderation/users'

export const Route = createFileRoute('/moderation/users')({
  validateSearch: validateUsersSearch,
  loaderDeps: ({ search }) => search,
  loader: async ({ context: { queryClient }, deps, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })

    if (session.user.twoFactorSetupRequired) throw redirect({ to: '/profile' })
    // Non-moderators get a 403 from the API, shown by the error view
    await queryClient.ensureInfiniteQueryData(moderationUsersQuery(filtersFromUsersSearch(deps)))
  },
  component: ModerationUsersRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function ModerationUsersRoute() {
  const filters = filtersFromUsersSearch(Route.useSearch())
  const navigate = Route.useNavigate()

  const onFiltersChange = useCallback(
    (changes: Partial<UserFilters>) =>
      navigate({
        replace: true,
        search: (prev) => usersSearchFromFilters({ ...filtersFromUsersSearch(prev), ...changes }),
      }),
    [navigate],
  )

  return <UsersModerationPage filters={filters} onFiltersChange={onFiltersChange} />
}
