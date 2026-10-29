import { useSuspenseQuery } from '@tanstack/react-query'
import { Link, useNavigate } from '@tanstack/react-router'
import { type FormEvent, useId, useState } from 'react'
import { useLdapLogin, useLogin, useTwoFactorLogin } from '@/api/mutations'
import { sessionQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'
import { OAuthButtons } from './OAuthButtons'

export function LoginPage({
  redirect,
  twoFactor = false,
}: {
  redirect?: string
  twoFactor?: boolean
}) {
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { t } = useI18n()
  const navigate = useNavigate()
  const login = useLogin()

  const emailId = useId()
  const passwordId = useId()
  const rememberId = useId()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [rememberMe, setRememberMe] = useState(false)
  // Second step for accounts with two-factor authentication
  const [codeStep, setCodeStep] = useState(twoFactor)
  // Company directory (LDAP) first, when the space has it
  const ldapLabel = session.tenant.ldapLabel
  const [mode, setMode] = useState<'ldap' | 'email'>(ldapLabel ? 'ldap' : 'email')

  const oauthProviders = session.tenant.oauthProviders
  const oauthOnly = session.tenant.settings.loginOnlyWithOauth && oauthProviders.length > 0
  const canRegister =
    !oauthOnly &&
    (session.tenant.settings.emailRegistrationPolicy !== 'none_allowed' ||
      oauthProviders.length > 0)

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    login.mutate(
      { email: email.trim(), password, rememberMe },
      {
        onSuccess: (result) => {
          if ('twoFactorRequired' in result) return setCodeStep(true)
          goOn()
        },
      },
    )
  }

  const goOn = () => {
    void (redirect ? navigate({ href: redirect }) : navigate({ to: '/' }))
  }

  if (codeStep) return <TwoFactorStep onSignedIn={goOn} onRestart={() => setCodeStep(false)} />

  return (
    <div className="mx-auto w-full max-w-md py-8">
      <div className="rounded-xl border border-border/80 bg-card p-6 shadow-xs sm:p-8">
        <h1 className="mb-6 text-center text-2xl font-bold tracking-tight">
          {t('common.forms.auth.log_in')}
        </h1>

        {ldapLabel && mode === 'ldap' ? (
          <div className="space-y-5">
            <LdapForm label={ldapLabel} onSignedIn={goOn} onTwoFactor={() => setCodeStep(true)} />
            {!oauthOnly && (
              <p className="text-center text-sm">
                <button
                  type="button"
                  className="text-muted-foreground hover:underline"
                  onClick={() => setMode('email')}
                >
                  {t('common.forms.auth.log_in_with_email')}
                </button>
              </p>
            )}
            <OAuthButtons providers={oauthProviders} mode="login" showDivider redirect={redirect} />
          </div>
        ) : oauthOnly ? (
          <div className="space-y-5">
            <p className="text-center text-sm text-muted-foreground">
              {t('common.forms.auth.oauth_only_info')}
            </p>
            <OAuthButtons providers={oauthProviders} mode="login" redirect={redirect} />
          </div>
        ) : (
          <div className="space-y-5">
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label htmlFor={emailId} className="block text-sm font-medium">
                  {t('common.forms.auth.email')}
                </label>
                <Input
                  id={emailId}
                  type="email"
                  required
                  autoComplete="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                />
              </div>

              <div className="space-y-1.5">
                <div className="flex items-center justify-between gap-2">
                  <label htmlFor={passwordId} className="block text-sm font-medium">
                    {t('common.forms.auth.password')}
                  </label>
                  <Link
                    to="/password/forgot"
                    className="text-xs font-medium text-primary hover:underline"
                  >
                    {t('common.forms.auth.forgot_password')}
                  </Link>
                </div>
                <Input
                  id={passwordId}
                  type="password"
                  required
                  autoComplete="current-password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                />
              </div>

              <div className="flex items-center gap-2">
                <Checkbox
                  id={rememberId}
                  checked={rememberMe}
                  onCheckedChange={(checked) => setRememberMe(checked === true)}
                />
                <label htmlFor={rememberId} className="cursor-pointer text-sm text-foreground">
                  {t('common.forms.auth.remember_me')}
                </label>
              </div>

              <FormError error={login.error} />

              <Button type="submit" className="h-10 w-full" disabled={login.isPending}>
                {t('common.forms.auth.log_in')}
              </Button>
            </form>
            {ldapLabel && (
              <p className="text-center text-sm">
                <button
                  type="button"
                  className="text-muted-foreground hover:underline"
                  onClick={() => setMode('ldap')}
                >
                  {t('common.forms.auth.log_in_with', { o_auth: ldapLabel })}
                </button>
              </p>
            )}

            <OAuthButtons providers={oauthProviders} mode="login" showDivider redirect={redirect} />
          </div>
        )}

        <div className="mt-6 space-y-2 border-t border-border/70 pt-4 text-center text-sm">
          {canRegister && (
            <p>
              <Link
                to="/register"
                search={{ redirect }}
                className="font-medium text-primary hover:underline"
              >
                {t('common.forms.auth.sign_up')}
              </Link>
            </p>
          )}
          <p>
            <Link to="/confirmation/new" className="text-muted-foreground hover:underline">
              {t('common.forms.auth.confirmation_instructions_not_received')}
            </Link>
          </p>
          <p>
            <Link to="/unlock/new" className="text-muted-foreground hover:underline">
              {t('common.forms.auth.unlock_instructions_not_received')}
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}

function TwoFactorStep(props: { onSignedIn: () => void; onRestart: () => void }) {
  const { t } = useI18n()
  const verify = useTwoFactorLogin()
  const codeId = useId()
  const [code, setCode] = useState('')

  return (
    <div className="mx-auto w-full max-w-md py-8">
      <div className="rounded-xl border border-border/80 bg-card p-6 shadow-xs sm:p-8">
        <h1 className="mb-2 text-center text-2xl font-bold tracking-tight">
          {t('two_factor.login_title')}
        </h1>
        <p className="mb-6 text-center text-sm text-muted-foreground">
          {t('two_factor.login_help')}
        </p>
        <form
          className="space-y-4"
          onSubmit={(event) => {
            event.preventDefault()
            verify.mutate(code.trim(), { onSuccess: props.onSignedIn })
          }}
        >
          <div className="space-y-1.5">
            <label htmlFor={codeId} className="block text-sm font-medium">
              {t('two_factor.code')}
            </label>
            <Input
              id={codeId}
              required
              autoFocus
              autoComplete="one-time-code"
              inputMode="text"
              spellCheck={false}
              value={code}
              onChange={(event) => setCode(event.target.value)}
            />
          </div>
          <FormError error={verify.error} />
          <Button type="submit" className="h-10 w-full" disabled={verify.isPending}>
            {t('two_factor.verify')}
          </Button>
        </form>
        <div className="mt-6 border-t border-border/70 pt-4 text-center text-sm">
          <button
            type="button"
            className="text-muted-foreground hover:underline"
            onClick={props.onRestart}
          >
            {t('two_factor.start_over')}
          </button>
        </div>
      </div>
    </div>
  )
}

// Login with the company directory: login name (not necessarily an email) and password
function LdapForm(props: { label: string; onSignedIn: () => void; onTwoFactor: () => void }) {
  const { t } = useI18n()
  const login = useLdapLogin()
  const loginId = useId()
  const passwordId = useId()
  const rememberId = useId()
  const [name, setName] = useState('')
  const [password, setPassword] = useState('')
  const [rememberMe, setRememberMe] = useState(false)

  return (
    <form
      className="space-y-4"
      onSubmit={(event) => {
        event.preventDefault()
        login.mutate(
          { login: name.trim(), password, rememberMe },
          {
            onSuccess: (result) =>
              'twoFactorRequired' in result ? props.onTwoFactor() : props.onSignedIn(),
          },
        )
      }}
    >
      <p className="text-center text-sm text-muted-foreground">
        {t('common.forms.auth.ldap_info', { label: props.label })}
      </p>
      <div className="space-y-1.5">
        <label htmlFor={loginId} className="block text-sm font-medium">
          {t('common.forms.auth.login_name')}
        </label>
        <Input
          id={loginId}
          required
          autoComplete="username"
          value={name}
          onChange={(event) => setName(event.target.value)}
        />
      </div>
      <div className="space-y-1.5">
        <label htmlFor={passwordId} className="block text-sm font-medium">
          {t('common.forms.auth.password')}
        </label>
        <Input
          id={passwordId}
          type="password"
          required
          autoComplete="current-password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
      </div>
      <div className="flex items-center gap-2">
        <Checkbox
          id={rememberId}
          checked={rememberMe}
          onCheckedChange={(checked) => setRememberMe(checked === true)}
        />
        <label htmlFor={rememberId} className="cursor-pointer text-sm text-foreground">
          {t('common.forms.auth.remember_me')}
        </label>
      </div>
      <FormError error={login.error} />
      <Button type="submit" className="h-10 w-full" disabled={login.isPending}>
        {t('common.forms.auth.log_in')}
      </Button>
    </form>
  )
}
