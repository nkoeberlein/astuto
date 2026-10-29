import { useQuery } from '@tanstack/react-query'
import type { WebhookDelivery } from '@/api/client'
import { webhookDeliveriesQuery } from '@/api/queries'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'

// Green "Delivered 201" or red "Failed 500" / "Failed" with the time
export function DeliveryStatus({ delivery }: { delivery: WebhookDelivery }) {
  const { t, locale } = useI18n()
  return (
    <span
      className={cn(
        'text-xs',
        delivery.success ? 'text-green-700 dark:text-green-400' : 'text-destructive',
      )}
    >
      {t('site_settings.webhooks.deliveries.last', {
        status: `${t(`site_settings.webhooks.deliveries.${delivery.success ? 'success' : 'failure'}`)}${
          delivery.httpStatus ? ` ${delivery.httpStatus}` : ''
        }`,
        when: formatRelativeTime(delivery.createdAt, locale),
      })}
    </span>
  )
}

// Delivery log of one webhook (#458): status, duration, error or response
export function WebhookDeliveries({ webhookId }: { webhookId: number }) {
  const { t, locale } = useI18n()
  const { data: deliveries, isPending } = useQuery(webhookDeliveriesQuery(webhookId))

  if (isPending) return <p className="text-sm text-muted-foreground">{t('common.loading')}</p>
  if (!deliveries?.length) {
    return (
      <p className="text-sm text-muted-foreground">
        {t('site_settings.webhooks.deliveries.empty')}
      </p>
    )
  }

  return (
    <div className="space-y-2">
      <h4 className="text-sm font-semibold">{t('site_settings.webhooks.deliveries.title')}</h4>
      <ul className="divide-y rounded-lg border text-sm">
        {deliveries.map((delivery) => (
          <li key={delivery.id} className="space-y-1 p-2">
            <p className="flex flex-wrap items-center gap-x-3 gap-y-1">
              <span
                className={cn(
                  'font-medium',
                  delivery.success ? 'text-green-700 dark:text-green-400' : 'text-destructive',
                )}
              >
                {t(`site_settings.webhooks.deliveries.${delivery.success ? 'success' : 'failure'}`)}
                {delivery.httpStatus ? ` · HTTP ${delivery.httpStatus}` : ''}
              </span>
              <time dateTime={delivery.createdAt} className="text-muted-foreground">
                {formatRelativeTime(delivery.createdAt, locale)}
              </time>
              {delivery.durationMs !== null && (
                <span className="text-muted-foreground tabular-nums">{delivery.durationMs} ms</span>
              )}
              {delivery.isTest && (
                <span className="rounded bg-muted px-1.5 text-xs text-muted-foreground">
                  {t('site_settings.webhooks.deliveries.test')}
                </span>
              )}
            </p>
            {(delivery.error || delivery.responseBody) && (
              <pre className="max-h-32 overflow-auto whitespace-pre-wrap break-all rounded bg-muted/60 p-2 font-mono text-xs">
                {delivery.error ?? delivery.responseBody}
              </pre>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}
