import { createFileRoute } from '@tanstack/react-router'
import { ResendInstructionsPage } from '@/features/auth/ResendInstructionsPage'
import { ErrorView } from '@/features/layout/ErrorView'

export const Route = createFileRoute('/unlock/new')({
  component: () => <ResendInstructionsPage kind="unlock" />,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
