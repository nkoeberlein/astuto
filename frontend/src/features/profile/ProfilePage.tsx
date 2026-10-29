import { useSuspenseQuery } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { KeyRound } from 'lucide-react'
import { type FormEvent, useState } from 'react'
import type { Profile } from '@/api/client'
import { useForgotPassword, useProfileMutations } from '@/api/mutations'
import { profileQuery } from '@/api/queries'
import { CopyButton } from '@/components/CopyButton'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import {
  CheckboxField,
  SelectField,
  SettingsSection,
  TextField,
} from '@/features/site-settings/fields'
import { useI18n } from '@/lib/i18n'
import { projectDocsUrl } from '@/lib/project'

// Profile settings (legacy: /users/edit)
export function ProfilePage() {
  const { t } = useI18n()
  const { data: profile } = useSuspenseQuery(profileQuery)

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <h1 className="text-2xl font-semibold tracking-tight">
        {t('common.forms.auth.profile_settings')}
      </h1>
      {!profile.hasSetPassword && <SetPasswordHint email={profile.email} />}
      <AccountSection key={`account-${profile.email}-${profile.fullName}`} profile={profile} />
      <NotificationsSection profile={profile} />
      {profile.hasSetPassword && <PasswordSection />}
      {profile.canHaveApiKey && <ApiKeySection current={profile.apiKey} />}
      <DataExportSection />
      {profile.canDeleteAccount && <DeleteAccountSection needsPassword={profile.hasSetPassword} />}
    </div>
  )
}

// Accounts created via OAuth have no password; email and password changes need one
function SetPasswordHint({ email }: { email: string }) {
  const { t } = useI18n()
  const forgot = useForgotPassword()
  return (
    <div className="flex flex-wrap items-center gap-3 rounded-lg border border-dashed p-4 text-sm">
      <p className="flex-1">{t('common.forms.auth.no_password_set')}</p>
      <Button
        type="button"
        size="sm"
        variant="outline"
        disabled={forgot.isPending || forgot.isSuccess}
        onClick={() => forgot.mutate({ email })}
      >
        {t('common.forms.auth.set_password')}
      </Button>
      {forgot.data && <p className="w-full text-muted-foreground">{forgot.data.message}</p>}
    </div>
  )
}

function useSave() {
  const { update } = useProfileMutations()
  const [busy, setBusy] = useState(false)
  const save = (event: FormEvent, changes: Parameters<typeof update.mutateAsync>[0]) => {
    event.preventDefault()
    setBusy(true)
    return update.mutateAsync(changes).finally(() => setBusy(false))
  }
  return { update, busy, save }
}

function AccountSection({ profile }: { profile: Profile }) {
  const { t } = useI18n()
  const { update, busy, save } = useSave()
  const [fullName, setFullName] = useState(profile.fullName)
  const [email, setEmail] = useState(profile.email)
  const [currentPassword, setCurrentPassword] = useState('')
  const emailChanged = email.trim().toLowerCase() !== profile.email.toLowerCase()

  return (
    <SettingsSection title={t('header.menu.profile_header')}>
      <form
        className="space-y-4"
        onSubmit={(event) =>
          save(event, {
            fullName,
            ...(emailChanged ? { email: email.trim(), currentPassword } : {}),
          }).catch(() => undefined)
        }
      >
        <TextField
          label={t('common.forms.auth.full_name')}
          value={fullName}
          onChange={setFullName}
        />
        <TextField
          label={t('common.forms.auth.email')}
          value={email}
          onChange={setEmail}
          help={
            profile.unconfirmedEmail
              ? t('common.forms.auth.waiting_confirmation', { email: profile.unconfirmedEmail })
              : undefined
          }
        />
        {emailChanged && profile.hasSetPassword && (
          <PasswordInput
            label={t('common.forms.auth.current_password')}
            value={currentPassword}
            onChange={setCurrentPassword}
            help={t('common.forms.auth.current_password_required_help')}
          />
        )}
        <SaveRow busy={busy} error={update.error} saved={update.isSuccess} />
      </form>
    </SettingsSection>
  )
}

function NotificationsSection({ profile }: { profile: Profile }) {
  const { t } = useI18n()
  const { update } = useProfileMutations()
  const frequencies = ['never', 'daily', 'weekly', 'monthly'] as const

  return (
    <SettingsSection title={t('common.forms.auth.notifications')}>
      <CheckboxField
        label={t('activerecord.attributes.user.notifications_enabled')}
        checked={profile.notificationsEnabled}
        onChange={(notificationsEnabled) => update.mutate({ notificationsEnabled })}
        help={t('common.forms.auth.notifications_enabled_help')}
      />
      {profile.recapAvailable && (
        <SelectField
          label={t('activerecord.attributes.user.recap_notification_frequency')}
          value={profile.recapNotificationFrequency}
          onChange={(recapNotificationFrequency) => update.mutate({ recapNotificationFrequency })}
          options={frequencies.map((frequency) => ({
            value: frequency,
            label: t(`common.forms.auth.recap_notification_frequency_${frequency}`),
          }))}
          help={t('common.forms.auth.recap_notification_frequency_help')}
        />
      )}
      <FormError error={update.error} />
    </SettingsSection>
  )
}

function PasswordSection() {
  const { t } = useI18n()
  const { update, busy, save } = useSave()
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [currentPassword, setCurrentPassword] = useState('')

  return (
    <SettingsSection title={t('common.forms.auth.change_password')}>
      <form
        className="space-y-4"
        onSubmit={(event) =>
          save(event, { password, passwordConfirmation: confirmation, currentPassword })
            .then(() => {
              setPassword('')
              setConfirmation('')
              setCurrentPassword('')
            })
            .catch(() => undefined)
        }
      >
        <PasswordInput
          label={t('common.forms.auth.new_password')}
          value={password}
          onChange={setPassword}
          autoComplete="new-password"
        />
        <PasswordInput
          label={t('common.forms.auth.new_password_confirmation')}
          value={confirmation}
          onChange={setConfirmation}
          autoComplete="new-password"
        />
        <PasswordInput
          label={t('common.forms.auth.current_password')}
          value={currentPassword}
          onChange={setCurrentPassword}
          help={t('common.forms.auth.current_password_required_help')}
        />
        <SaveRow busy={busy || !password} error={update.error} saved={update.isSuccess} />
      </form>
    </SettingsSection>
  )
}

function ApiKeySection({ current }: { current: string | null }) {
  const { t } = useI18n()
  const { generateApiKey } = useProfileMutations()
  const key = generateApiKey.data?.apiKey

  return (
    <SettingsSection title={t('common.forms.api_key.title')}>
      <a
        href={projectDocsUrl('api.md')}
        target="_blank"
        rel="noopener"
        className="text-sm text-primary underline-offset-4 hover:underline"
      >
        {t('common.forms.api_key.api_key_learn_more')}
      </a>
      {key ? (
        <div className="space-y-2">
          <p className="text-sm font-medium">
            {t('common.forms.api_key.generated_api_key_successfully')}
          </p>
          <code className="block break-all rounded bg-muted p-2 font-mono text-xs">{key}</code>
          <div className="flex flex-wrap items-center gap-3">
            <CopyButton text={key} />
            <p className="text-sm text-muted-foreground">
              {t('common.forms.api_key.generated_api_key_help')}
            </p>
          </div>
        </div>
      ) : (
        current && (
          <div className="space-y-1">
            <code className="block break-all font-mono text-xs text-muted-foreground">
              {current}
            </code>
            <p className="text-sm text-muted-foreground">
              {t('common.forms.api_key.current_api_key_help')}
            </p>
          </div>
        )
      )}
      <Button
        type="button"
        variant="outline"
        disabled={generateApiKey.isPending}
        onClick={() => {
          if (!current || window.confirm(t('common.forms.api_key.confirm_generate_new_api_key'))) {
            generateApiKey.mutate()
          }
        }}
      >
        <KeyRound className="size-4" aria-hidden />
        {t('common.forms.api_key.generate_api_key')}
      </Button>
      <FormError error={generateApiKey.error} />
    </SettingsSection>
  )
}

// GDPR: a JSON file with profile, posts, comments, votes and follows
function DataExportSection() {
  const { t } = useI18n()
  return (
    <SettingsSection title={t('common.forms.auth.my_data')}>
      <p className="text-sm text-muted-foreground">{t('common.forms.auth.my_data_help')}</p>
      <Button asChild variant="outline">
        <a href="/api/app/v1/profile/export" download>
          {t('common.forms.auth.download_my_data')}
        </a>
      </Button>
    </SettingsSection>
  )
}

function DeleteAccountSection({ needsPassword }: { needsPassword: boolean }) {
  const { t } = useI18n()
  const { remove } = useProfileMutations()
  const navigate = useNavigate()
  const [currentPassword, setCurrentPassword] = useState('')

  return (
    <SettingsSection title={t('common.forms.auth.cancel_account')}>
      <form
        className="space-y-4"
        onSubmit={(event) => {
          event.preventDefault()
          if (!window.confirm(t('common.confirmation'))) return
          remove.mutate(currentPassword, { onSuccess: () => navigate({ to: '/' }) })
        }}
      >
        {needsPassword && (
          <PasswordInput
            label={t('common.forms.auth.current_password')}
            value={currentPassword}
            onChange={setCurrentPassword}
          />
        )}
        <Button type="submit" variant="destructive" disabled={remove.isPending}>
          {t('common.forms.auth.cancel_account')}
        </Button>
        <FormError error={remove.error} />
      </form>
    </SettingsSection>
  )
}

function PasswordInput(props: {
  label: string
  value: string
  onChange: (value: string) => void
  help?: string
  autoComplete?: string
}) {
  return (
    <TextField
      type="password"
      label={props.label}
      value={props.value}
      onChange={props.onChange}
      help={props.help}
      autoComplete={props.autoComplete ?? 'current-password'}
    />
  )
}

function SaveRow(props: { busy: boolean; error: Error | null; saved: boolean }) {
  const { t } = useI18n()
  return (
    <div className="flex flex-wrap items-center gap-3">
      <Button type="submit" disabled={props.busy}>
        {t('common.buttons.update')}
      </Button>
      {props.saved && !props.error && (
        <span className="text-sm text-muted-foreground" aria-live="polite">
          {t('site_settings.info_box.up_to_date')}
        </span>
      )}
      <FormError error={props.error} />
    </div>
  )
}
