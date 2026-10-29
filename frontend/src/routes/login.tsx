import { createFileRoute, redirect } from '@tanstack/react-router'
import { sessionQuery } from '@/api/queries'
import { LoginPage } from '@/features/auth/LoginPage'
import { safeRedirect } from '@/features/auth/redirect'
import { ErrorView } from '@/features/layout/ErrorView'

type LoginSearch = {
  // Page to return to after sign-in (a local path)
  redirect?: string
}

export const Route = createFileRoute('/login')({
  validateSearch: (search: Record<string, unknown>): LoginSearch => ({
    redirect: safeRedirect(search.redirect),
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
  const { redirect: redirectTo } = Route.useSearch()
  return <LoginPage redirect={redirectTo} />
}
