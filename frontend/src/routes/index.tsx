import { createFileRoute, redirect } from '@tanstack/react-router'
import { boardsQuery, sessionQuery } from '@/api/queries'
import { useI18n } from '@/lib/i18n'

// Start page: the configured root board, otherwise the first board
export const Route = createFileRoute('/')({
  loader: async ({ context: { queryClient } }) => {
    const [session, boards] = await Promise.all([
      queryClient.ensureQueryData(sessionQuery),
      queryClient.ensureQueryData(boardsQuery),
    ])
    const rootBoardId = session.tenant.settings.rootBoardId
    const board = boards.find((b) => b.id === rootBoardId) ?? boards[0]
    if (board) throw redirect({ to: '/boards/$boardSlug', params: { boardSlug: board.slug } })
  },
  component: NoBoards,
})

function NoBoards() {
  const { t } = useI18n()
  return <p className="text-center text-muted-foreground">{t('board.posts_list.empty')}</p>
}
