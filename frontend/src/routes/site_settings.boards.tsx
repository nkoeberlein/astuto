import { createFileRoute } from '@tanstack/react-router'
import { boardsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { BoardsSettingsPage } from '@/features/site-settings/BoardsSettingsPage'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'

export const Route = createFileRoute('/site_settings/boards')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await Promise.all([queryClient.ensureQueryData(boardsQuery)])
  },
  component: () => (
    <SiteSettingsLayout>
      <BoardsSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
