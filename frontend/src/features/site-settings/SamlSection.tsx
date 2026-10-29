import { useSuspenseQuery } from '@tanstack/react-query'
import { useState } from 'react'
import type { SamlSettings, UpdateSamlSettings } from '@/api/client'
import { useSamlMutations } from '@/api/mutations'
import { samlSettingsQuery } from '@/api/queries'
import { CopyButton } from '@/components/CopyButton'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'
import { CheckboxField, SettingsSection, TextField } from './fields'

type Draft = Required<{ [K in keyof UpdateSamlSettings]: NonNullable<UpdateSamlSettings[K]> }>

function draftFrom(settings: SamlSettings): Draft {
  return {
    enabled: settings.enabled,
    label: settings.label,
    idpEntityId: settings.idpEntityId ?? '',
    idpSsoUrl: settings.idpSsoUrl ?? '',
    idpCert: settings.idpCert ?? '',
    emailAttribute: settings.emailAttribute ?? '',
    nameAttribute: settings.nameAttribute ?? '',
    autoCreateUsers: settings.autoCreateUsers,
  }
}

// Site settings › Authentication › SAML single sign-on (Entra ID, Okta, Keycloak, ADFS, ...)
export function SamlSection() {
  const { t } = useI18n()
  const { data: settings } = useSuspenseQuery(samlSettingsQuery)
  const { save, parseMetadata } = useSamlMutations()
  const [draft, setDraft] = useState<Draft>(() => draftFrom(settings))
  const [metadata, setMetadata] = useState('')
  const set = <K extends keyof Draft>(key: K, value: Draft[K]) =>
    setDraft((d) => ({ ...d, [key]: value }))
  const label = (field: string) => t(`activerecord.attributes.saml_config.${field}`)
  const spValues: [string, string][] = [
    [t('site_settings.authentication.saml.sp_entity_id'), settings.spEntityId],
    [t('site_settings.authentication.saml.acs_url'), settings.acsUrl],
  ]

  return (
    <SettingsSection title={t('site_settings.authentication.saml.title')}>
      <p className="text-sm text-muted-foreground">
        {t('site_settings.authentication.saml.intro')}
      </p>

      <dl className="space-y-2 rounded-lg border bg-muted/40 p-3 text-sm">
        {spValues.map(([name, value]) => (
          <div key={name} className="flex flex-wrap items-center gap-2">
            <dt className="text-muted-foreground">{name}</dt>
            <dd className="flex min-w-0 items-center gap-2">
              <code className="break-all">{value}</code>
              <CopyButton text={value} />
            </dd>
          </div>
        ))}
      </dl>

      <form
        className="space-y-3"
        onSubmit={(event) => {
          event.preventDefault()
          parseMetadata.mutate(metadata, {
            onSuccess: (fields) =>
              setDraft((d) => ({
                ...d,
                idpEntityId: fields.idpEntityId ?? d.idpEntityId,
                idpSsoUrl: fields.idpSsoUrl,
                idpCert: fields.idpCert ?? d.idpCert,
              })),
          })
        }}
      >
        <Label htmlFor="saml-metadata">{t('site_settings.authentication.saml.metadata')}</Label>
        <Textarea
          id="saml-metadata"
          rows={3}
          value={metadata}
          onChange={(event) => setMetadata(event.target.value)}
          placeholder="<EntityDescriptor …>"
          className="font-mono text-xs"
        />
        <FormError error={parseMetadata.error} />
        <Button
          type="submit"
          variant="outline"
          disabled={!metadata.trim() || parseMetadata.isPending}
        >
          {t('site_settings.authentication.saml.import_metadata')}
        </Button>
      </form>

      <form
        className="space-y-4 border-t pt-4"
        onSubmit={(event) => {
          event.preventDefault()
          save.mutate(
            {
              ...draft,
              emailAttribute: draft.emailAttribute || null,
              nameAttribute: draft.nameAttribute || null,
            },
            { onSuccess: (saved) => setDraft(draftFrom(saved)) },
          )
        }}
      >
        <TextField
          label={label('idp_entity_id')}
          value={draft.idpEntityId}
          onChange={(v) => set('idpEntityId', v)}
        />
        <TextField
          label={label('idp_sso_url')}
          type="url"
          value={draft.idpSsoUrl}
          onChange={(v) => set('idpSsoUrl', v)}
        />
        <div className="space-y-1.5">
          <Label htmlFor="saml-cert">{label('idp_cert')}</Label>
          <Textarea
            id="saml-cert"
            rows={4}
            value={draft.idpCert}
            onChange={(event) => set('idpCert', event.target.value)}
            placeholder="-----BEGIN CERTIFICATE-----"
            className="font-mono text-xs"
          />
        </div>
        <TextField
          label={label('email_attribute')}
          value={draft.emailAttribute}
          onChange={(v) => set('emailAttribute', v)}
          help={t('site_settings.authentication.saml.email_attribute_help')}
        />
        <TextField
          label={label('name_attribute')}
          value={draft.nameAttribute}
          onChange={(v) => set('nameAttribute', v)}
        />
        <TextField label={label('label')} value={draft.label} onChange={(v) => set('label', v)} />
        <CheckboxField
          label={label('auto_create_users')}
          checked={draft.autoCreateUsers}
          onChange={(v) => set('autoCreateUsers', v)}
          help={t('site_settings.authentication.saml.auto_create_help')}
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
    </SettingsSection>
  )
}
