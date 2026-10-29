import { createFileRoute, redirect } from '@tanstack/react-router'
import { boardsQuery, moderationPostsQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { FeedbackModerationPage } from '@/features/moderation/FeedbackModerationPage'
import type { ModerationTab } from '@/features/moderation/queue'

type ModerationSearch = { tab?: 'rejected' }

export const Route = createFileRoute('/moderation/feedback')({
  validateSearch: (search: Record<string, unknown>): ModerationSearch => ({
    tab: search.tab === 'rejected' ? 'rejected' : undefined,
  }),
  loader: async ({ context: { queryClient }, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })

    // Non-moderators get a 403 from the API, shown by the error view
    await Promise.all([
      queryClient.ensureQueryData(moderationPostsQuery),
      queryClient.ensureQueryData(boardsQuery),
    ])
  },
  component: ModerationFeedbackRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function ModerationFeedbackRoute() {
  const tab: ModerationTab = Route.useSearch().tab ?? 'pending'
  return <FeedbackModerationPage tab={tab} />
}
