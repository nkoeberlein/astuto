import { createFileRoute } from '@tanstack/react-router'
import { tagsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { requireAdmin } from '@/features/site-settings/route'
import { SiteSettingsLayout } from '@/features/site-settings/SiteSettingsLayout'
import { TagsSettingsPage } from '@/features/site-settings/TagsSettingsPage'

export const Route = createFileRoute('/site_settings/tags')({
  loader: async ({ context: { queryClient }, location }) => {
    await requireAdmin(queryClient, location)
    await queryClient.ensureQueryData(tagsQuery)
  },
  component: () => (
    <SiteSettingsLayout>
      <TagsSettingsPage />
    </SiteSettingsLayout>
  ),
  errorComponent: ({ error }) => <ErrorView error={error} />,
})
