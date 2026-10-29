import { createFileRoute, redirect } from '@tanstack/react-router'
import { sessionQuery } from '@/api/queries'
import { LoginPage } from '@/features/auth/LoginPage'
import { safeRedirect } from '@/features/auth/redirect'
import { ErrorView } from '@/features/layout/ErrorView'

type LoginSearch = {
  // Page to return to after sign-in (a local path)
  redirect?: string
  // After an OAuth login of an account with two-factor authentication: ask for the code
  two_factor?: 1
}

export const Route = createFileRoute('/login')({
  validateSearch: (search: Record<string, unknown>): LoginSearch => ({
    redirect: safeRedirect(search.redirect),
    two_factor: search.two_factor === 1 || search.two_factor === '1' ? 1 : undefined,
  }),
  beforeLoad: async ({ context: { queryClient }, search }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) return
    if (search.redirect) throw redirect({ href: search.redirect })
    throw redirect({ to: '/' })
  },
  component: LoginRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function LoginRoute() {
  const { redirect: redirectTo, two_factor: twoFactor } = Route.useSearch()
  return <LoginPage redirect={redirectTo} twoFactor={twoFactor === 1} />
}
