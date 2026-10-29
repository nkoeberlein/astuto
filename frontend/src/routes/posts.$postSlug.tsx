import { createFileRoute, redirect } from '@tanstack/react-router'
import { boardsQuery, commentsQuery, postQuery, postStatusesQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { PostPage } from '@/features/posts/PostPage'

export const Route = createFileRoute('/posts/$postSlug')({
  loader: async ({ context: { queryClient }, params }) => {
    const post = await queryClient.ensureQueryData(postQuery(params.postSlug))
    // A merged duplicate (or an old slug) answers with the post it stands for
    if (post.slug !== params.postSlug) {
      throw redirect({ to: '/posts/$postSlug', params: { postSlug: post.slug }, replace: true })
    }
    await Promise.all([
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
