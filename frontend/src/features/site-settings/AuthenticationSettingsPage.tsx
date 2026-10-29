import { useSuspenseQuery } from '@tanstack/react-query'
import { BookOpen, FlaskConical, Pencil, Plus, Trash2 } from 'lucide-react'
import { type FormEvent, useState } from 'react'
import type { OAuthInput, OAuthSettings } from '@/api/client'
import { useOAuthMutations, useUpdateGeneralSettings } from '@/api/mutations'
import { generalSettingsQuery, oAuthSettingsQuery } from '@/api/queries'
import { CopyButton } from '@/components/CopyButton'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { useI18n } from '@/lib/i18n'
import { projectDocsUrl } from '@/lib/project'
import { CheckboxField, SelectField, SettingsSection, TextField } from './fields'
import { HeaderRows } from './HeaderRows'
import { LdapSection } from './LdapSection'
import { SamlSection } from './SamlSection'

// Site settings › Authentication (legacy: /site_settings/authentication):
// email registration rules and OAuth providers
export function AuthenticationSettingsPage() {
  const { t } = useI18n()
  return (
    <div className="space-y-6">
      <h2 className="text-xl font-semibold tracking-tight">
        {t('site_settings.authentication.title')}
      </h2>
      <EmailRegistrationSection />
      <OAuthSection />
      <SamlSection />
      <LdapSection />
    </div>
  )
}

type RegistrationPolicy = 'all_allowed' | 'custom_domains_allowed' | 'none_allowed'

function EmailRegistrationSection() {
  const { t } = useI18n()
  const { data: settings } = useSuspenseQuery(generalSettingsQuery)
  const save = useUpdateGeneralSettings()
  const [policy, setPolicy] = useState<RegistrationPolicy>(settings.emailRegistrationPolicy)
  const [domains, setDomains] = useState(settings.allowedEmailDomains ?? '')
  const dirty =
    policy !== settings.emailRegistrationPolicy || domains !== (settings.allowedEmailDomains ?? '')

  return (
    <SettingsSection title={t('site_settings.authentication.email_registration_subtitle')}>
      <form
        className="space-y-4"
        onSubmit={(event) => {
          event.preventDefault()
          save.mutate({
            emailRegistrationPolicy: policy,
            allowedEmailDomains: domains.trim() || null,
          })
        }}
      >
        <SelectField
          label={t('activerecord.attributes.tenant_setting.email_registration_policy')}
          value={policy}
          onChange={setPolicy}
          options={[
            {
              value: 'all_allowed',
              label: t('site_settings.authentication.email_registration_policy_all'),
            },
            {
              value: 'custom_domains_allowed',
              label: t('site_settings.authentication.email_registration_policy_custom'),
            },
            {
              value: 'none_allowed',
              label: t('site_settings.authentication.email_registration_policy_none'),
            },
          ]}
        />
        {policy === 'custom_domains_allowed' && (
          <TextField
            label={t('activerecord.attributes.tenant_setting.allowed_email_domains')}
            value={domains}
            onChange={setDomains}
            placeholder="example.com,example.org"
            help={t('site_settings.authentication.allowed_email_domains_help')}
          />
        )}
        <div className="flex flex-wrap items-center gap-3">
          <Button type="submit" disabled={!dirty || save.isPending}>
            {t('common.buttons.update')}
          </Button>
          {save.isSuccess && !dirty && (
            <span className="text-sm text-muted-foreground">
              {t('site_settings.info_box.up_to_date')}
            </span>
          )}
          <FormError error={save.error} />
        </div>
      </form>
    </SettingsSection>
  )
}

function OAuthSection() {
  const { t } = useI18n()
  const { data: oAuths } = useSuspenseQuery(oAuthSettingsQuery)
  const { create, update, remove, setDefaultEnabled } = useOAuthMutations()
  const [editing, setEditing] = useState<number | 'new' | null>(null)
  const error = create.error ?? update.error ?? remove.error ?? setDefaultEnabled.error

  const open = (id: number | 'new' | null) => {
    for (const mutation of [create, update, remove, setDefaultEnabled]) mutation.reset()
    setEditing(id)
  }

  return (
    <SettingsSection title={t('site_settings.authentication.oauth_subtitle')}>
      <a
        href={projectDocsUrl('oauth.md')}
        target="_blank"
        rel="noopener"
        className="inline-flex items-center gap-1.5 text-sm text-primary underline-offset-4 hover:underline"
      >
        <BookOpen className="size-4" aria-hidden />
        {t('site_settings.authentication.learn_more')}
      </a>
      <FormError error={error} />

      {oAuths.length === 0 && (
        <p className="rounded-lg border border-dashed p-4 text-center text-sm text-muted-foreground">
          {t('site_settings.authentication.empty')}
        </p>
      )}
      <ul className="divide-y rounded-lg border empty:hidden">
        {oAuths.map((oAuth) =>
          editing === oAuth.id ? (
            <li key={oAuth.id} className="p-4">
              <OAuthForm
                oAuth={oAuth}
                onSubmit={(input) =>
                  update.mutateAsync({ id: oAuth.id, ...input }).then(() => open(null))
                }
                onCancel={() => open(null)}
              />
            </li>
          ) : (
            <OAuthRow
              key={oAuth.id}
              oAuth={oAuth}
              onToggle={(enabled) =>
                oAuth.isDefault
                  ? setDefaultEnabled.mutate({ id: oAuth.id, enabled })
                  : update.mutate({ id: oAuth.id, isEnabled: enabled })
              }
              onEdit={() => open(oAuth.id)}
              onDelete={() => {
                if (window.confirm(t('common.confirmation'))) remove.mutate(oAuth.id)
              }}
            />
          ),
        )}
      </ul>

      {editing === 'new' ? (
        <div className="rounded-lg border p-4">
          <h3 className="mb-4 font-semibold">{t('site_settings.authentication.form.title_new')}</h3>
          <OAuthForm
            onSubmit={(input) => create.mutateAsync(input).then(() => open(null))}
            onCancel={() => open(null)}
          />
        </div>
      ) : (
        <Button type="button" variant="outline" onClick={() => open('new')}>
          <Plus className="size-4" aria-hidden />
          {t('common.buttons.new')}
        </Button>
      )}
    </SettingsSection>
  )
}

function OAuthRow(props: {
  oAuth: OAuthSettings
  onToggle: (enabled: boolean) => void
  onEdit: () => void
  onDelete: () => void
}) {
  const { t } = useI18n()
  const { oAuth } = props
  const switchId = `oauth-enabled-${oAuth.id}`

  return (
    <li className="flex flex-col gap-3 p-4 sm:flex-row sm:items-center">
      <div className="flex min-w-0 flex-1 items-center gap-3">
        {oAuth.logo ? (
          <img src={oAuth.logo} alt="" className="size-8 shrink-0 object-contain" />
        ) : (
          <span className="size-8 shrink-0 rounded bg-muted" aria-hidden />
        )}
        <div className="min-w-0">
          <p className="truncate font-medium">{oAuth.name}</p>
          {oAuth.isDefault && (
            <p className="text-xs text-muted-foreground">
              {t('site_settings.authentication.default_oauth')}
            </p>
          )}
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <span className="flex items-center gap-2 text-sm">
          <Checkbox
            id={switchId}
            checked={oAuth.isEnabled}
            onCheckedChange={(checked) => props.onToggle(checked === true)}
          />
          <label htmlFor={switchId}>{t('common.enabled')}</label>
        </span>
        <CopyButton text={oAuth.callbackUrl} label={t('site_settings.authentication.copy_url')} />
        <Button
          type="button"
          size="sm"
          variant="outline"
          onClick={() => window.open(oAuth.testUrl, '', 'width=640,height=640')}
        >
          <FlaskConical className="size-4" aria-hidden />
          {t('common.buttons.test')}
        </Button>
        {!oAuth.isDefault && (
          <>
            <Button
              type="button"
              size="icon"
              variant="ghost"
              className="size-8 text-muted-foreground"
              aria-label={`${oAuth.name}: ${t('common.buttons.edit')}`}
              title={t('common.buttons.edit')}
              onClick={props.onEdit}
            >
              <Pencil className="size-4" aria-hidden />
            </Button>
            <Button
              type="button"
              size="icon"
              variant="ghost"
              className="size-8 text-destructive hover:text-destructive"
              aria-label={`${oAuth.name}: ${t('common.buttons.delete')}`}
              title={t('common.buttons.delete')}
              onClick={props.onDelete}
            >
              <Trash2 className="size-4" aria-hidden />
            </Button>
          </>
        )}
      </div>
    </li>
  )
}

type OAuthDraft = Required<{ [K in keyof OAuthInput]: NonNullable<OAuthInput[K]> }>

function OAuthForm(props: {
  oAuth?: OAuthSettings
  onSubmit: (input: OAuthInput) => Promise<unknown>
  onCancel: () => void
}) {
  const { t } = useI18n()
  const o = props.oAuth
  const [draft, setDraft] = useState<OAuthDraft>({
    name: o?.name ?? '',
    logo: o?.logo ?? '',
    isEnabled: o?.isEnabled ?? false,
    clientId: o?.clientId ?? '',
    clientSecret: '',
    authorizeUrl: o?.authorizeUrl ?? '',
    tokenUrl: o?.tokenUrl ?? '',
    profileUrl: o?.profileUrl ?? '',
    scope: o?.scope ?? '',
    jsonUserNamePath: o?.jsonUserNamePath ?? '',
    jsonUserEmailPath: o?.jsonUserEmailPath ?? '',
    profileHeaders: o?.profileHeaders ?? [],
  })
  const [busy, setBusy] = useState(false)
  const label = (field: string) => t(`activerecord.attributes.o_auth.${field}`)
  const field = (key: keyof OAuthDraft, name: string, type: 'text' | 'url' = 'text') => (
    <TextField
      label={label(name)}
      type={type}
      value={String(draft[key])}
      onChange={(value) => setDraft({ ...draft, [key]: value })}
    />
  )

  const submit = (event: FormEvent) => {
    event.preventDefault()
    setBusy(true)
    props
      .onSubmit({
        ...draft,
        logo: draft.logo || null,
        jsonUserNamePath: draft.jsonUserNamePath || null,
      })
      .catch(() => undefined)
      .finally(() => setBusy(false))
  }

  return (
    <form className="space-y-4" onSubmit={submit}>
      {field('name', 'name')}
      {field('logo', 'logo', 'url')}
      <CheckboxField
        label={label('is_enabled')}
        checked={draft.isEnabled}
        onChange={(isEnabled) => setDraft({ ...draft, isEnabled })}
      />
      <h4 className="pt-2 text-sm font-semibold">
        {t('site_settings.authentication.form.subtitle_oauth_config')}
      </h4>
      {field('clientId', 'client_id')}
      <TextField
        label={label('client_secret')}
        value={draft.clientSecret}
        onChange={(clientSecret) => setDraft({ ...draft, clientSecret })}
        placeholder={o ? '••••••••' : undefined}
        help={o ? t('site_settings.authentication.form.client_secret_help') : undefined}
      />
      {field('authorizeUrl', 'authorize_url', 'url')}
      {field('tokenUrl', 'token_url', 'url')}
      {field('scope', 'scope')}
      <h4 className="pt-2 text-sm font-semibold">
        {t('site_settings.authentication.form.subtitle_user_profile_config')}
      </h4>
      {field('profileUrl', 'profile_url', 'url')}
      {field('jsonUserEmailPath', 'json_user_email_path')}
      {field('jsonUserNamePath', 'json_user_name_path')}
      <HeaderRows
        legend={t('site_settings.authentication.form.profile_headers')}
        rows={draft.profileHeaders}
        onChange={(profileHeaders) => setDraft({ ...draft, profileHeaders })}
        keyPlaceholder="User-Agent"
        valuePlaceholder="Astuto"
      />
      <div className="flex gap-2">
        <Button type="submit" disabled={busy}>
          {o ? t('common.buttons.update') : t('common.buttons.create')}
        </Button>
        <Button type="button" variant="ghost" onClick={props.onCancel}>
          {t('common.buttons.cancel')}
        </Button>
      </div>
    </form>
  )
}
