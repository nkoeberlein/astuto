import { Link } from '@tanstack/react-router'
import { useI18n } from '@/lib/i18n'

const linkClass =
  'rounded-lg px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-foreground'
const activeClass = 'bg-primary/10 font-semibold text-primary ring-1 ring-primary/20'

// Heading and section links shared by the moderation pages
export function ModerationNav() {
  const { t } = useI18n()

  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <h1 className="text-2xl font-semibold tracking-tight">{t('header.menu.moderation')}</h1>
      <nav className="flex gap-1" aria-label={t('header.menu.moderation')}>
        <Link
          to="/moderation/feedback"
          className={linkClass}
          activeProps={{ className: activeClass }}
        >
          {t('moderation.menu.feedback')}
        </Link>
        <Link to="/moderation/users" className={linkClass} activeProps={{ className: activeClass }}>
          {t('moderation.menu.users')}
        </Link>
      </nav>
    </div>
  )
}
