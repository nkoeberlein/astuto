import { createFileRoute, redirect } from '@tanstack/react-router'
import { type MyPostsFilter, myPostsQuery, postStatusesQuery, sessionQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { MyFeedbackPage } from '@/features/my-feedback/MyFeedbackPage'

type MyFeedbackSearch = { filter?: Exclude<MyPostsFilter, 'created'> }

export const Route = createFileRoute('/my-feedback')({
  validateSearch: (search: Record<string, unknown>): MyFeedbackSearch => ({
    filter: search.filter === 'voted' || search.filter === 'followed' ? search.filter : undefined,
  }),
  loaderDeps: ({ search }): { filter: MyPostsFilter } => ({ filter: search.filter ?? 'created' }),
  loader: async ({ context: { queryClient }, deps, location }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })
    await Promise.all([
      queryClient.ensureQueryData(postStatusesQuery),
      queryClient.ensureInfiniteQueryData(myPostsQuery(deps.filter)),
    ])
  },
  component: MyFeedbackRoute,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function MyFeedbackRoute() {
  const filter: MyPostsFilter = Route.useSearch().filter ?? 'created'
  return <MyFeedbackPage filter={filter} />
}
