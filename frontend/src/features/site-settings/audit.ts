import type { TFunction } from '@/lib/i18n'

// The translation, or the fallback when the key is missing (t returns the key itself then)
export function translatedOr(t: TFunction, key: string, fallback: string): string {
  const text = t(key)
  return text === key ? fallback : text
}

// A changed value as text: "—" for nothing, yes/no for booleans, JSON for lists and objects
export function auditValue(value: unknown, t: TFunction): string {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'boolean')
    return t(value ? 'site_settings.audit_log.value_yes' : 'site_settings.audit_log.value_no')
  if (typeof value === 'string')
    return value === '[filtered]' ? t('site_settings.audit_log.filtered') : value
  if (typeof value === 'number') return String(value)
  return JSON.stringify(value)
}
