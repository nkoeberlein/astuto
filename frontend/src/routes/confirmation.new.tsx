import { createFileRoute } from '@tanstack/react-router'
import { ResendInstructionsPage } from '@/features/auth/ResendInstructionsPage'
import { ErrorView } from '@/features/layout/ErrorView'

export const Route = createFileRoute('/confirmation/new')({
  component: () => <ResendInstructionsPage kind="confirmation" />,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
