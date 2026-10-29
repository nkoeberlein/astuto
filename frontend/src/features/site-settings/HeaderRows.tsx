import { Plus, X } from 'lucide-react'
import type { WebhookHeader } from '@/api/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'

type Props = {
  legend: string
  rows: WebhookHeader[]
  onChange: (rows: WebhookHeader[]) => void
  keyPlaceholder?: string
  valuePlaceholder?: string
}

// Editable HTTP header rows (webhooks, OAuth profile request); empty rows are dropped on save
export function HeaderRows({ legend, rows, onChange, keyPlaceholder, valuePlaceholder }: Props) {
  const { t } = useI18n()
  const update = (index: number, change: Partial<WebhookHeader>) =>
    onChange(rows.map((row, i) => (i === index ? { ...row, ...change } : row)))

  return (
    <fieldset className="space-y-2">
      <legend className="text-sm font-medium">{legend}</legend>
      {rows.map((row, index) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: rows have no id and are edited in place
        <div key={index} className="flex gap-2">
          <Input
            value={row.key}
            onChange={(event) => update(index, { key: event.target.value })}
            placeholder={keyPlaceholder}
            aria-label={t('site_settings.webhooks.form.header_n_key', { n: index + 1 })}
            className="font-mono text-sm"
          />
          <Input
            value={row.value}
            onChange={(event) => update(index, { value: event.target.value })}
            placeholder={valuePlaceholder}
            aria-label={t('site_settings.webhooks.form.header_n_value', { n: index + 1 })}
            className="font-mono text-sm"
          />
          <Button
            type="button"
            size="icon"
            variant="ghost"
            className="shrink-0 text-muted-foreground"
            aria-label={`${t('common.buttons.delete')} ${index + 1}`}
            onClick={() => onChange(rows.filter((_, i) => i !== index))}
          >
            <X className="size-4" aria-hidden />
          </Button>
        </div>
      ))}
      <Button
        type="button"
        size="sm"
        variant="ghost"
        onClick={() => onChange([...rows, { key: '', value: '' }])}
      >
        <Plus className="size-4" aria-hidden />
        {t('site_settings.webhooks.form.add_header')}
      </Button>
    </fieldset>
  )
}
