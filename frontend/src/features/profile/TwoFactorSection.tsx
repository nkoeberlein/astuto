import { ShieldCheck } from 'lucide-react'
import { useState } from 'react'
import type { Profile } from '@/api/client'
import { useTwoFactorMutations } from '@/api/mutations'
import { CopyButton } from '@/components/CopyButton'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { SettingsSection, TextField } from '@/features/site-settings/fields'
import { useI18n } from '@/lib/i18n'

// Profile › Two-factor authentication: set up with an authenticator app, backup codes, turn off
export function TwoFactorSection({ profile }: { profile: Profile }) {
  const { t } = useI18n()
  const [backupCodes, setBackupCodes] = useState<string[] | null>(null)

  return (
    <SettingsSection title={t('two_factor.title')}>
      {profile.twoFactorRequired && !profile.twoFactorEnabled && (
        <p
          role="alert"
          className="rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-sm"
        >
          {t('two_factor.required_notice')}
        </p>
      )}
      {backupCodes ? (
        <BackupCodes codes={backupCodes} onDone={() => setBackupCodes(null)} />
      ) : profile.twoFactorEnabled ? (
        <Enabled profile={profile} onNewCodes={setBackupCodes} />
      ) : (
        <Setup needsPassword={profile.hasSetPassword} onEnabled={setBackupCodes} />
      )}
    </SettingsSection>
  )
}

function Setup(props: { needsPassword: boolean; onEnabled: (codes: string[]) => void }) {
  const { t } = useI18n()
  const { start, confirm } = useTwoFactorMutations()
  const [password, setPassword] = useState('')
  const [code, setCode] = useState('')
  const setup = start.data

  if (!setup) {
    return (
      <form
        className="space-y-4"
        onSubmit={(event) => {
          event.preventDefault()
          start.mutate(password)
        }}
      >
        <p className="text-sm text-muted-foreground">{t('two_factor.intro')}</p>
        {props.needsPassword && (
          <TextField
            type="password"
            label={t('common.forms.auth.current_password')}
            value={password}
            onChange={setPassword}
            autoComplete="current-password"
          />
        )}
        <FormError error={start.error} />
        <Button type="submit" disabled={start.isPending}>
          {t('two_factor.set_up')}
        </Button>
      </form>
    )
  }

  return (
    <form
      className="space-y-4"
      onSubmit={(event) => {
        event.preventDefault()
        confirm.mutate(code.trim(), { onSuccess: (result) => props.onEnabled(result.backupCodes) })
      }}
    >
      <p className="text-sm">{t('two_factor.scan_help')}</p>
      <img
        src={setup.qrCode}
        alt={t('two_factor.qr_code_alt')}
        className="size-48 rounded-lg border bg-white p-2"
      />
      <div className="flex flex-wrap items-center gap-2 text-sm">
        <span className="text-muted-foreground">{t('two_factor.manual_entry')}</span>
        <code className="rounded bg-muted px-2 py-1 font-mono">{setup.secret}</code>
        <CopyButton text={setup.secret.replaceAll(' ', '')} />
      </div>
      <TextField
        label={t('two_factor.code')}
        value={code}
        onChange={setCode}
        autoComplete="one-time-code"
      />
      <FormError error={confirm.error} />
      <Button type="submit" disabled={confirm.isPending}>
        {t('two_factor.turn_on')}
      </Button>
    </form>
  )
}

function Enabled(props: { profile: Profile; onNewCodes: (codes: string[]) => void }) {
  const { t } = useI18n()
  const { regenerate, disable } = useTwoFactorMutations()
  const [password, setPassword] = useState('')
  const [code, setCode] = useState('')
  const needsPassword = props.profile.hasSetPassword

  return (
    <div className="space-y-5">
      <p className="flex items-center gap-2 text-sm">
        <ShieldCheck className="size-4 text-emerald-600" aria-hidden />
        {t('two_factor.enabled', { count: props.profile.backupCodesLeft })}
      </p>

      <TextField
        label={t('two_factor.code')}
        value={code}
        onChange={setCode}
        autoComplete="one-time-code"
        help={t('two_factor.code_for_changes')}
      />
      <div className="flex flex-wrap gap-2">
        <Button
          type="button"
          variant="outline"
          disabled={regenerate.isPending || !code.trim()}
          onClick={() =>
            regenerate.mutate(code.trim(), {
              onSuccess: (result) => props.onNewCodes(result.backupCodes),
            })
          }
        >
          {t('two_factor.new_backup_codes')}
        </Button>
      </div>
      <FormError error={regenerate.error} />

      <form
        className="space-y-3 border-t pt-4"
        onSubmit={(event) => {
          event.preventDefault()
          if (!window.confirm(t('two_factor.turn_off_confirmation'))) return
          disable.mutate(needsPassword ? { currentPassword: password } : { code: code.trim() })
        }}
      >
        {needsPassword && (
          <TextField
            type="password"
            label={t('common.forms.auth.current_password')}
            value={password}
            onChange={setPassword}
            autoComplete="current-password"
          />
        )}
        <FormError error={disable.error} />
        <Button type="submit" variant="destructive" disabled={disable.isPending}>
          {t('two_factor.turn_off')}
        </Button>
      </form>
    </div>
  )
}

function BackupCodes(props: { codes: string[]; onDone: () => void }) {
  const { t } = useI18n()
  return (
    <div className="space-y-4">
      <p className="text-sm" role="status">
        {t('two_factor.backup_codes_help')}
      </p>
      <ul
        className="grid grid-cols-2 gap-2 font-mono text-sm sm:grid-cols-5"
        aria-label={t('two_factor.backup_codes')}
      >
        {props.codes.map((code) => (
          <li key={code} className="rounded bg-muted px-2 py-1 text-center">
            {code}
          </li>
        ))}
      </ul>
      <div className="flex flex-wrap gap-2">
        <CopyButton text={props.codes.join('\n')} />
        <Button type="button" onClick={props.onDone}>
          {t('two_factor.saved_codes')}
        </Button>
      </div>
    </div>
  )
}
