import { createFileRoute } from '@tanstack/react-router'
import { ForgotPasswordPage } from '@/features/auth/ForgotPasswordPage'
import { ErrorView } from '@/features/layout/ErrorView'

export const Route = createFileRoute('/password/forgot')({
  component: ForgotPasswordPage,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
