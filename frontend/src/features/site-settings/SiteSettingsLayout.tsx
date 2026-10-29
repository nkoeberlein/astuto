import { Link } from '@tanstack/react-router'
import { ExternalLink } from 'lucide-react'
import type { ReactNode } from 'react'
import { useI18n } from '@/lib/i18n'

// Sections rebuilt in the v2 frontend
const V2_SECTIONS = ['general', 'boards', 'post_statuses', 'roadmap'] as const

// Sections still in the legacy UI open there until they are rebuilt
const LEGACY_SECTIONS = ['authentication', 'invitations', 'appearance', 'webhooks'] as const

const itemClass =
  'flex items-center justify-between gap-2 whitespace-nowrap rounded-lg px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-foreground'

export function SiteSettingsLayout({ children }: { children: ReactNode }) {
  const { t } = useI18n()

  return (
    <div className="mx-auto grid max-w-5xl gap-6 md:grid-cols-[13rem_1fr]">
      <nav aria-label={t('site_settings.menu.title')} className="space-y-3">
        <h1 className="text-2xl font-semibold tracking-tight">{t('site_settings.menu.title')}</h1>
        <ul className="-mx-1 flex gap-1 overflow-x-auto md:flex-col md:overflow-visible">
          {V2_SECTIONS.map((section) => (
            <li key={section}>
              <Link
                to={`/site_settings/${section}`}
                className={itemClass}
                activeProps={{
                  className: 'bg-primary/10 font-semibold text-primary ring-1 ring-primary/20',
                }}
              >
                {t(`site_settings.menu.${section}`)}
              </Link>
            </li>
          ))}
          {LEGACY_SECTIONS.map((section) => (
            <li key={section}>
              <a href={`/site_settings/${section}`} className={itemClass}>
                {t(`site_settings.menu.${section}`)}
                <ExternalLink className="size-3.5 opacity-60" aria-hidden />
              </a>
            </li>
          ))}
        </ul>
      </nav>
      <div className="min-w-0">{children}</div>
    </div>
  )
}
