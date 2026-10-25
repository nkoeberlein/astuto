import { createFileRoute } from '@tanstack/react-router'
import { ResetPasswordPage } from '@/features/auth/ResetPasswordPage'
import { ErrorView } from '@/features/layout/ErrorView'

type ResetPasswordSearch = {
  reset_password_token: string
}

export const Route = createFileRoute('/password/reset')({
  validateSearch: (search: Record<string, unknown>): ResetPasswordSearch => ({
    reset_password_token:
      typeof search.reset_password_token === 'string' ? search.reset_password_token : '',
  }),
  component: ResetPasswordRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function ResetPasswordRoute() {
  const { reset_password_token } = Route.useSearch()
  return <ResetPasswordPage resetPasswordToken={reset_password_token} />
}
