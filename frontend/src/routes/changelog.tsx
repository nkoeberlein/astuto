import { createFileRoute } from '@tanstack/react-router'
import { changelogQuery, sessionQuery } from '@/api/queries'
import { ChangelogPage } from '@/features/changelog/ChangelogPage'
import { ErrorView } from '@/features/layout/ErrorView'

export const Route = createFileRoute('/changelog')({
  loader: async ({ context: { queryClient } }) => {
    await Promise.all([
      queryClient.ensureQueryData(sessionQuery),
      queryClient.ensureInfiniteQueryData(changelogQuery),
    ])
  },
  component: ChangelogPage,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
