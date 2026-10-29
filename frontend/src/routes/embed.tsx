import { createFileRoute } from '@tanstack/react-router'
import { boardsQuery, postStatusesQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { EmbedPage } from '@/features/widget/EmbedPage'

// Feedback widget for other sites (public/widget.js, docs/widget.md). The root layout leaves
// out header and footer; SpaController allows framing while the widget is on.
export const Route = createFileRoute('/embed')({
  staticData: { embedded: true },
  loader: async ({ context: { queryClient } }) => {
    await Promise.all([
      queryClient.ensureQueryData(sessionQuery),
      queryClient.ensureQueryData(boardsQuery),
      queryClient.ensureQueryData(postStatusesQuery),
    ])
  },
  component: EmbedPage,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
