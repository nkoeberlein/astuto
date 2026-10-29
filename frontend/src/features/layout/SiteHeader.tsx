import { Link } from '@tanstack/react-router'
import { LogOut, Settings, ShieldCheck } from 'lucide-react'
import type { Board, Session } from '@/api/client'
import { useLogout } from '@/api/mutations'
import { EvoLogo } from '@/components/EvoLogo'
import { UserAvatar } from '@/components/UserAvatar'
import { Button } from '@/components/ui/button'
import { useLoginRedirect } from '@/features/auth/redirect'
import { useI18n } from '@/lib/i18n'
import { isAdmin, isModerator } from '@/lib/roles'

export function SiteHeader({ session, boards }: { session: Session; boards: Board[] }) {
  const { t } = useI18n()
  const loginRedirect = useLoginRedirect()
  const logout = useLogout()
  const { tenant, user } = session
  const showLogo = ['name_and_logo', 'logo_only'].includes(tenant.settings.brandDisplay)
  const showName = ['name_and_logo', 'name_only'].includes(tenant.settings.brandDisplay)
  const brandContent = (
    <>
      {showLogo &&
        (tenant.siteLogo ? (
          <img src={tenant.siteLogo} alt="" className="h-8 w-auto rounded-md" />
        ) : (
          <EvoLogo className="size-8" />
        ))}
      {showName && <span>{tenant.siteName}</span>}
    </>
  )

  return (
    <header className="sticky top-0 z-30 border-b bg-card/85 shadow-2xs backdrop-blur-md">
      <div className="flex w-full flex-wrap items-center justify-between gap-x-6 gap-y-2 px-4 py-3 sm:px-6 lg:px-10">
        {tenant.settings.logoLinksTo === 'nothing' ? (
          <span className="flex items-center gap-2.5 font-semibold tracking-tight">
            {brandContent}
          </span>
        ) : tenant.settings.logoLinksTo === 'custom_url' && tenant.settings.logoCustomUrl ? (
          <a
            href={tenant.settings.logoCustomUrl}
            className="flex items-center gap-2.5 font-semibold tracking-tight"
          >
            {brandContent}
          </a>
        ) : (
          <Link to="/" className="flex items-center gap-2.5 font-semibold tracking-tight">
            {brandContent}
          </Link>
        )}

        <nav
          className="order-last -mx-1 flex w-full gap-1 overflow-x-auto text-sm sm:order-none sm:w-auto sm:flex-1"
          aria-label="Boards"
        >
          {tenant.settings.roadmapEnabled && tenant.settings.showRoadmapInHeader && (
            <Link
              to="/roadmap"
              className="whitespace-nowrap rounded-lg px-3 py-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
              activeProps={{
                className: 'bg-primary/10 text-primary font-semibold ring-1 ring-primary/20',
              }}
            >
              {t('roadmap.title')}
            </Link>
          )}
          {boards.map((board) => (
            <Link
              key={board.id}
              to="/boards/$boardSlug"
              params={{ boardSlug: board.slug }}
              className="whitespace-nowrap rounded-lg px-3 py-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
              activeProps={{
                className: 'bg-primary/10 text-primary font-semibold ring-1 ring-primary/20',
              }}
            >
              {board.name}
            </Link>
          ))}
          {tenant.settings.customLinks.map((link) => (
            <a
              key={link.url}
              href={link.url}
              className="whitespace-nowrap rounded-lg px-3 py-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
            >
              {link.label}
            </a>
          ))}
        </nav>

        {user ? (
          <div className="flex items-center gap-2 text-sm font-medium">
            {isModerator(user) && <ModerationLink pendingCount={session.pendingPostsCount ?? 0} />}
            {isAdmin(user) && (
              <Link
                to="/site_settings/general"
                className="rounded-lg p-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
                activeProps={{ className: 'text-primary' }}
                aria-label={t('header.menu.site_settings')}
                title={t('header.menu.site_settings')}
              >
                <Settings className="size-4" aria-hidden />
              </Link>
            )}
            <UserAvatar name={user.fullName} url={user.avatarUrl} />
            <span className="hidden sm:inline">{user.fullName}</span>
            <Button
              type="button"
              size="sm"
              variant="ghost"
              disabled={logout.isPending}
              onClick={() => logout.mutate()}
              aria-label={t('header.menu.sign_out')}
              title={t('header.menu.sign_out')}
              className="gap-1.5 text-muted-foreground hover:text-foreground"
            >
              <LogOut className="size-4" aria-hidden />
              <span className="hidden md:inline">{t('header.menu.sign_out')}</span>
            </Button>
          </div>
        ) : (
          <Button asChild size="sm" variant="outline">
            <Link to="/login" search={{ redirect: loginRedirect }}>
              {t('header.log_in')}
            </Link>
          </Button>
        )}
      </div>
    </header>
  )
}

// Feedback queue for moderators; the badge counts posts waiting for approval
function ModerationLink({ pendingCount }: { pendingCount: number }) {
  const { t } = useI18n()
  const label = t('header.menu.moderation')

  return (
    <Link
      to="/moderation/feedback"
      className="relative flex items-center gap-1.5 rounded-lg px-2 py-1.5 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
      activeProps={{ className: 'text-primary' }}
      aria-label={pendingCount > 0 ? `${label} (${pendingCount})` : label}
      title={label}
    >
      <ShieldCheck className="size-4" aria-hidden />
      <span className="hidden md:inline">{label}</span>
      {pendingCount > 0 && (
        <span
          className="min-w-5 rounded-full bg-primary px-1.5 text-center text-xs font-semibold text-primary-foreground tabular-nums"
          aria-hidden
        >
          {pendingCount}
        </span>
      )}
    </Link>
  )
}
