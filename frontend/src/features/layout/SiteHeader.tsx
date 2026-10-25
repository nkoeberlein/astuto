import { Link } from '@tanstack/react-router'
import type { Board, Session } from '@/api/client'
import { UserAvatar } from '@/components/UserAvatar'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'

export function SiteHeader({ session, boards }: { session: Session; boards: Board[] }) {
  const { t } = useI18n()
  const { tenant, user } = session
  const showLogo =
    tenant.siteLogo && ['name_and_logo', 'logo_only'].includes(tenant.settings.brandDisplay)
  const showName = ['name_and_logo', 'name_only'].includes(tenant.settings.brandDisplay)

  return (
    <header className="border-b bg-card">
      <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-x-6 gap-y-2 px-4 py-3">
        <Link to="/" className="flex items-center gap-2 font-semibold">
          {showLogo && <img src={tenant.siteLogo ?? ''} alt="" className="h-8 w-auto" />}
          {showName && <span>{tenant.siteName}</span>}
        </Link>

        <nav
          className="order-last -mx-1 flex w-full gap-1 overflow-x-auto text-sm sm:order-none sm:w-auto sm:flex-1"
          aria-label="Boards"
        >
          {tenant.settings.roadmapEnabled && tenant.settings.showRoadmapInHeader && (
            <Link
              to="/roadmap"
              className="whitespace-nowrap rounded-md px-3 py-1.5 text-muted-foreground hover:bg-accent"
              activeProps={{ className: 'bg-accent text-foreground font-medium' }}
            >
              {t('roadmap.title')}
            </Link>
          )}
          {boards.map((board) => (
            <Link
              key={board.id}
              to="/boards/$boardSlug"
              params={{ boardSlug: board.slug }}
              className="whitespace-nowrap rounded-md px-3 py-1.5 text-muted-foreground hover:bg-accent"
              activeProps={{ className: 'bg-accent text-foreground font-medium' }}
            >
              {board.name}
            </Link>
          ))}
          {tenant.settings.customLinks.map((link) => (
            <a
              key={link.url}
              href={link.url}
              className="whitespace-nowrap rounded-md px-3 py-1.5 text-muted-foreground hover:bg-accent"
            >
              {link.label}
            </a>
          ))}
        </nav>

        {user ? (
          <div className="flex items-center gap-2 text-sm">
            <UserAvatar name={user.fullName} url={user.avatarUrl} />
            <span className="hidden sm:inline">{user.fullName}</span>
          </div>
        ) : (
          <Button asChild size="sm" variant="outline">
            <a href="/users/sign_in">{t('header.log_in')}</a>
          </Button>
        )}
      </div>
    </header>
  )
}
