import { createFileRoute } from '@tanstack/react-router'
import { boardsQuery, commentsQuery, postQuery, postStatusesQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { PostPage } from '@/features/posts/PostPage'

export const Route = createFileRoute('/posts/$postSlug')({
  loader: async ({ context: { queryClient }, params }) => {
    await Promise.all([
      queryClient.ensureQueryData(postQuery(params.postSlug)),
      queryClient.ensureQueryData(commentsQuery(params.postSlug)),
      queryClient.ensureQueryData(postStatusesQuery),
      queryClient.ensureQueryData(boardsQuery),
    ])
  },
  component: function PostRoute() {
    return <PostPage postSlug={Route.useParams().postSlug} />
  },
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
