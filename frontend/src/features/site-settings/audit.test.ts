import { describe, expect, it } from 'vitest'
import { auditValue, translatedOr } from './audit'

const t = (key: string) =>
  ({
    'site_settings.audit_log.value_yes': 'Yes',
    'site_settings.audit_log.value_no': 'No',
    'site_settings.audit_log.filtered': '(hidden)',
    'activerecord.attributes.post.title': 'Title',
  })[key] ?? key

describe('audit log values', () => {
  it('formats changed values', () => {
    expect(auditValue(null, t)).toBe('—')
    expect(auditValue('', t)).toBe('—')
    expect(auditValue(true, t)).toBe('Yes')
    expect(auditValue(false, t)).toBe('No')
    expect(auditValue(3, t)).toBe('3')
    expect(auditValue('[filtered]', t)).toBe('(hidden)')
    expect(auditValue([{ label: 'Docs' }], t)).toBe('[{"label":"Docs"}]')
  })

  it('falls back when a translation is missing', () => {
    expect(translatedOr(t, 'activerecord.attributes.post.title', 'post.title')).toBe('Title')
    expect(translatedOr(t, 'activerecord.attributes.webhook.http_body', 'webhook.http_body')).toBe(
      'webhook.http_body',
    )
  })
})
