import { EvoBadge, EvoLogo } from '@/components/EvoLogo'
import { useI18n } from '@/lib/i18n'
import { PROJECT_NAME, PROJECT_REPOSITORY_URL } from '@/lib/project'

export function SiteFooter({ showPoweredBy }: { showPoweredBy: boolean }) {
  const { t } = useI18n()
  if (!showPoweredBy) return null
  return (
    <footer className="py-6 text-center text-xs text-muted-foreground">
      <a
        href={PROJECT_REPOSITORY_URL}
        target="_blank"
        rel="noreferrer"
        className="inline-flex items-center gap-1.5 hover:text-foreground hover:underline"
      >
        <EvoLogo className="size-4" />
        <span>
          {t('common.powered_by')} {PROJECT_NAME}
        </span>
        <EvoBadge className="px-1.5 py-0 text-[9px]" />
      </a>
    </footer>
  )
}
