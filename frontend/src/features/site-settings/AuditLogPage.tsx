import { useInfiniteQuery } from '@tanstack/react-query'
import { useState } from 'react'
import type { AuditChange, AuditEvent } from '@/api/client'
import { AUDIT_CATEGORIES, type AuditCategory, auditEventsQuery } from '@/api/queries'
import { FilterChip } from '@/components/FilterChip'
import { Button } from '@/components/ui/button'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { auditValue, translatedOr } from './audit'

// Site settings › Audit log: who changed what in moderation and settings (admins)
export function AuditLogPage() {
  const { t } = useI18n()
  const [category, setCategory] = useState<AuditCategory | null>(null)
  const query = useInfiniteQuery(auditEventsQuery(category))
  const events = query.data?.pages.flatMap((page) => page.events) ?? []

  return (
    <div className="space-y-6">
      <div className="space-y-1">
        <h2 className="text-xl font-semibold tracking-tight">
          {t('site_settings.menu.audit_log')}
        </h2>
        <p className="text-sm text-muted-foreground">{t('site_settings.audit_log.description')}</p>
      </div>

      <fieldset className="flex flex-wrap gap-2">
        <legend className="sr-only">{t('site_settings.audit_log.filter')}</legend>
        <FilterChip active={category === null} onClick={() => setCategory(null)}>
          {t('site_settings.audit_log.all')}
        </FilterChip>
        {AUDIT_CATEGORIES.map((key) => (
          <FilterChip key={key} active={category === key} onClick={() => setCategory(key)}>
            {t(`site_settings.audit_log.categories.${key}`)}
          </FilterChip>
        ))}
      </fieldset>

      {query.isPending ? null : events.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t('site_settings.audit_log.empty')}</p>
      ) : (
        <ol className="divide-y rounded-xl border bg-card">
          {events.map((event) => (
            <AuditEntry key={event.id} event={event} />
          ))}
        </ol>
      )}

      {query.hasNextPage && (
        <Button
          variant="outline"
          onClick={() => query.fetchNextPage()}
          disabled={query.isFetchingNextPage}
        >
          {t('site_settings.audit_log.load_more')}
        </Button>
      )}
    </div>
  )
}

function AuditEntry({ event }: { event: AuditEvent }) {
  const { t, locale } = useI18n()
  const action = translatedOr(
    t,
    `site_settings.audit_log.actions.${event.action.replace('.', '_')}`,
    event.action,
  )

  return (
    <li className="space-y-1.5 px-4 py-3 text-sm">
      <div className="flex flex-wrap items-baseline gap-x-2 gap-y-1">
        <span className="font-medium">
          {event.actorName ?? t('site_settings.audit_log.unknown_actor')}
        </span>
        <span>{action}</span>
        {event.subjectLabel &&
          (event.subjectPath ? (
            <a href={event.subjectPath} className="font-medium text-primary hover:underline">
              {event.subjectLabel}
            </a>
          ) : (
            <span className="font-medium">{event.subjectLabel}</span>
          ))}
        {event.source !== 'app' && (
          <span className="rounded border px-1.5 text-xs text-muted-foreground">
            {t(`site_settings.audit_log.sources.${event.source}`)}
          </span>
        )}
        <time
          dateTime={event.createdAt}
          title={new Date(event.createdAt).toLocaleString(locale)}
          className="ms-auto text-xs text-muted-foreground"
        >
          {formatRelativeTime(event.createdAt, locale)}
        </time>
      </div>
      {event.changes.length > 0 && (
        <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-0.5 text-xs">
          {event.changes.map((change) => (
            <ChangeRow key={change.field} change={change} />
          ))}
        </dl>
      )}
      {event.ip && <p className="text-xs text-muted-foreground">IP {event.ip}</p>}
    </li>
  )
}

function ChangeRow({ change }: { change: AuditChange }) {
  const { t } = useI18n()
  const label = translatedOr(t, `activerecord.attributes.${change.field}`, change.field)
  return (
    <>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="min-w-0 break-words">
        <span className="text-muted-foreground line-through">{auditValue(change.from, t)}</span>
        {' → '}
        <span>{auditValue(change.to, t)}</span>
      </dd>
    </>
  )
}
