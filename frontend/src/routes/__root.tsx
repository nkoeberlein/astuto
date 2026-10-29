import type { QueryClient } from '@tanstack/react-query'
import { useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { createRootRouteWithContext, Outlet, useMatches } from '@tanstack/react-router'
import { useEffect } from 'react'
import type { Session } from '@/api/client'
import { boardsQuery, sessionQuery, translationsQuery } from '@/api/queries'
import { FlashMessages } from '@/components/FlashMessages'
import { TwoFactorSetupBanner } from '@/components/TwoFactorSetupBanner'
import { ErrorView } from '@/features/layout/ErrorView'
import { SiteFooter } from '@/features/layout/SiteFooter'
import { SiteHeader } from '@/features/layout/SiteHeader'
import { escapeCustomCss } from '@/lib/custom-css'
import { I18nProvider, textDirection } from '@/lib/i18n'

export type RouterContext = { queryClient: QueryClient }

declare module '@tanstack/react-router' {
  interface StaticDataRouteOption {
    // Page for an iframe on another site: no header and footer
    embedded?: boolean
  }
}

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
  const embedded = useMatches({ select: (matches) => matches.some((m) => m.staticData.embedded) })

  useEffect(() => {
    document.documentElement.lang = tenant.locale
    document.documentElement.dir = textDirection(tenant.locale)
    document.title = tenant.siteName
    if (tenant.siteFavicon) {
      const icon = document.querySelector<HTMLLinkElement>('link[rel="icon"]')
      if (icon) icon.href = tenant.siteFavicon
    }
  }, [tenant.locale, tenant.siteName, tenant.siteFavicon])

  return (
    <I18nProvider locale={tenant.locale} translations={translations}>
      {tenant.settings.customCss && (
        <style data-astuto-custom-css>{escapeCustomCss(tenant.settings.customCss)}</style>
      )}
      {embedded ? (
        <main className="w-full px-4 py-4">
          <Outlet />
        </main>
      ) : (
        <div className="flex min-h-dvh flex-col">
          <HeaderWithBoards />
          <TwoFactorSetupBanner />
          <FlashMessages />
          <main className="w-full flex-1 px-4 py-6 sm:px-6 lg:px-10">
            <Outlet />
          </main>
          <SiteFooter showPoweredBy={tenant.settings.showPoweredBy} />
        </div>
      )}
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
