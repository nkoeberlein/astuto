import { useSuspenseQuery } from '@tanstack/react-query'
import { useState } from 'react'
import type { LdapSettings } from '@/api/client'
import { useLdapMutations } from '@/api/mutations'
import { ldapSettingsQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'
import { CheckboxField, SelectField, SettingsSection, TextField } from './fields'

type Encryption = LdapSettings['encryption']

type Draft = Omit<LdapSettings, 'bindPasswordSet' | 'host' | 'baseDn' | 'bindDn' | 'port'> & {
  host: string
  baseDn: string
  bindDn: string
  port: string
  bindPassword: string
}

function draftFrom(settings: LdapSettings): Draft {
  const { bindPasswordSet: _set, ...rest } = settings
  return {
    ...rest,
    host: settings.host ?? '',
    baseDn: settings.baseDn ?? '',
    bindDn: settings.bindDn ?? '',
    port: String(settings.port),
    bindPassword: '',
  }
}

// Site settings › Authentication › LDAP / Active Directory
export function LdapSection() {
  const { t } = useI18n()
  const { data: settings } = useSuspenseQuery(ldapSettingsQuery)
  const { save, test } = useLdapMutations()
  const [draft, setDraft] = useState<Draft>(() => draftFrom(settings))
  const [testLogin, setTestLogin] = useState('')
  const set = <K extends keyof Draft>(key: K, value: Draft[K]) =>
    setDraft((d) => ({ ...d, [key]: value }))
  const label = (field: string) => t(`activerecord.attributes.ldap_config.${field}`)
  const help = (key: string) => t(`site_settings.authentication.ldap.${key}`)

  return (
    <SettingsSection title={help('title')}>
      <p className="text-sm text-muted-foreground">{help('intro')}</p>
      <form
        className="space-y-4"
        onSubmit={(event) => {
          event.preventDefault()
          const { bindPassword, port, ...rest } = draft
          save.mutate(
            {
              ...rest,
              port: Number.parseInt(port, 10) || 389,
              host: rest.host || null,
              baseDn: rest.baseDn || null,
              bindDn: rest.bindDn || null,
              ...(bindPassword ? { bindPassword } : {}),
            },
            { onSuccess: (saved) => setDraft(draftFrom(saved)) },
          )
        }}
      >
        <div className="grid gap-4 sm:grid-cols-[1fr_8rem]">
          <TextField
            label={label('host')}
            value={draft.host}
            onChange={(v) => set('host', v)}
            placeholder="ldap.example.com"
          />
          <TextField
            label={label('port')}
            type="number"
            value={draft.port}
            onChange={(v) => set('port', v)}
          />
        </div>
        <SelectField<Encryption>
          label={label('encryption')}
          value={draft.encryption}
          onChange={(v) => set('encryption', v)}
          options={(['start_tls', 'simple_tls', 'plain'] as const).map((value) => ({
            value,
            label: help(`encryption_${value}`),
          }))}
        />
        {draft.encryption !== 'plain' && (
          <CheckboxField
            label={label('verify_certificate')}
            checked={draft.verifyCertificate}
            onChange={(v) => set('verifyCertificate', v)}
          />
        )}
        <TextField
          label={label('base_dn')}
          value={draft.baseDn}
          onChange={(v) => set('baseDn', v)}
          placeholder="ou=people,dc=example,dc=com"
        />
        <TextField
          label={label('bind_dn')}
          value={draft.bindDn}
          onChange={(v) => set('bindDn', v)}
          placeholder="cn=astuto,ou=services,dc=example,dc=com"
          help={help('bind_dn_help')}
        />
        <TextField
          label={label('bind_password')}
          type="password"
          value={draft.bindPassword}
          onChange={(v) => set('bindPassword', v)}
          autoComplete="new-password"
          help={settings.bindPasswordSet ? help('bind_password_set') : undefined}
        />
        <TextField
          label={label('user_filter')}
          value={draft.userFilter}
          onChange={(v) => set('userFilter', v)}
          help={help('user_filter_help')}
        />
        <div className="grid gap-4 sm:grid-cols-2">
          <TextField
            label={label('email_attribute')}
            value={draft.emailAttribute}
            onChange={(v) => set('emailAttribute', v)}
          />
          <TextField
            label={label('name_attribute')}
            value={draft.nameAttribute}
            onChange={(v) => set('nameAttribute', v)}
          />
        </div>
        <TextField label={label('label')} value={draft.label} onChange={(v) => set('label', v)} />
        <CheckboxField
          label={label('auto_create_users')}
          checked={draft.autoCreateUsers}
          onChange={(v) => set('autoCreateUsers', v)}
        />
        <CheckboxField
          label={label('enabled')}
          checked={draft.enabled}
          onChange={(v) => set('enabled', v)}
        />
        <FormError error={save.error} />
        <Button type="submit" disabled={save.isPending}>
          {t('common.buttons.update')}
        </Button>
      </form>

      <form
        className="space-y-3 border-t pt-4"
        onSubmit={(event) => {
          event.preventDefault()
          test.mutate(testLogin.trim())
        }}
      >
        <TextField
          label={help('test_login')}
          value={testLogin}
          onChange={setTestLogin}
          help={help('test_help')}
        />
        <Button type="submit" variant="outline" disabled={!testLogin.trim() || test.isPending}>
          {t('common.buttons.test')}
        </Button>
        <FormError error={test.error} />
        {test.data && (
          <p role="status" className="text-sm">
            {help('test_found')} <code className="break-all">{test.data.dn}</code> ·{' '}
            {test.data.email ?? '—'} · {test.data.name ?? '—'}
          </p>
        )}
      </form>
    </SettingsSection>
  )
}
