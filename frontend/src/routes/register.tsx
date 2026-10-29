import { createFileRoute, redirect } from '@tanstack/react-router'
import { sessionQuery } from '@/api/queries'
import { RegisterPage } from '@/features/auth/RegisterPage'
import { safeRedirect } from '@/features/auth/redirect'
import { ErrorView } from '@/features/layout/ErrorView'

type RegisterSearch = {
  email?: string
  invitation_token?: string
  // Page to return to after sign-up (a local path)
  redirect?: string
}

export const Route = createFileRoute('/register')({
  validateSearch: (search: Record<string, unknown>): RegisterSearch => ({
    email: typeof search.email === 'string' && search.email ? search.email : undefined,
    invitation_token:
      typeof search.invitation_token === 'string' && search.invitation_token
        ? search.invitation_token
        : undefined,
    redirect: safeRedirect(search.redirect),
  }),
  beforeLoad: async ({ context: { queryClient }, search }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) return
    if (search.redirect) throw redirect({ href: search.redirect })
    throw redirect({ to: '/' })
  },
  component: RegisterRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function RegisterRoute() {
  const { email, invitation_token, redirect: redirectTo } = Route.useSearch()
  return (
    <RegisterPage initialEmail={email} invitationToken={invitation_token} redirect={redirectTo} />
  )
}
