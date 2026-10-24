import type { QueryClient } from '@tanstack/react-query'
import { useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import { useEffect } from 'react'
import type { Session } from '@/api/client'
import { boardsQuery, sessionQuery, translationsQuery } from '@/api/queries'
import { ErrorView } from '@/features/layout/ErrorView'
import { SiteFooter } from '@/features/layout/SiteFooter'
import { SiteHeader } from '@/features/layout/SiteHeader'
import { I18nProvider } from '@/lib/i18n'

export type RouterContext = { queryClient: QueryClient }

export const Route = createRootRouteWithContext<RouterContext>()({
  loader: async ({ context: { queryClient } }) => {
    const session = await queryClient.ensureQueryData(sessionQuery)
    await Promise.all([
      queryClient.ensureQueryData(translationsQuery(session.tenant.locale)),
      canSeeBoards(session) ? queryClient.ensureQueryData(boardsQuery) : undefined,
    ])
  },
  component: RootLayout,
  errorComponent: ({ error }) => <ErrorView error={error} />,
})

function RootLayout() {
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: translations } = useSuspenseQuery(translationsQuery(session.tenant.locale))
  const { tenant } = session

  useEffect(() => {
    document.documentElement.lang = tenant.locale
    document.title = tenant.siteName
  }, [tenant.locale, tenant.siteName])

  return (
    <I18nProvider locale={tenant.locale} translations={translations}>
      <div className="flex min-h-dvh flex-col">
        <HeaderWithBoards />
        <main className="mx-auto w-full max-w-5xl flex-1 px-4 py-8">
          <Outlet />
        </main>
        <SiteFooter showPoweredBy={tenant.settings.showPoweredBy} />
      </div>
    </I18nProvider>
  )
}

// Anonymous visitors of private feedback spaces cannot read boards
function canSeeBoards(session: Session) {
  return !session.tenant.settings.isPrivate || session.user !== null
}

function HeaderWithBoards() {
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: boards = [] } = useQuery({ ...boardsQuery, enabled: canSeeBoards(session) })
  return <SiteHeader session={session} boards={boards} />
}
