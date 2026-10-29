import { useSuspenseQuery } from '@tanstack/react-query'
import { Link, useNavigate } from '@tanstack/react-router'
import { type FormEvent, useId, useState } from 'react'
import { useRegister } from '@/api/mutations'
import { sessionQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'
import { OAuthButtons } from './OAuthButtons'

export function RegisterPage({
  initialEmail = '',
  invitationToken,
  redirect,
}: {
  initialEmail?: string
  invitationToken?: string
  redirect?: string
}) {
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { t } = useI18n()
  const navigate = useNavigate()
  const register = useRegister()

  const fullNameId = useId()
  const emailId = useId()
  const passwordId = useId()
  const passwordConfirmationId = useId()

  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState(initialEmail)
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [confirmationMessage, setConfirmationMessage] = useState<string | null>(null)

  const oauthProviders = session.tenant.oauthProviders
  const hasInvitation = Boolean(invitationToken)
  const oauthOnly =
    !hasInvitation && session.tenant.settings.loginOnlyWithOauth && oauthProviders.length > 0
  const emailRegistrationBlocked =
    !hasInvitation && session.tenant.settings.emailRegistrationPolicy === 'none_allowed'

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    register.mutate(
      {
        fullName: fullName.trim(),
        email: email.trim(),
        password,
        passwordConfirmation,
        ...(invitationToken ? { invitationToken } : {}),
      },
      {
        onSuccess: (result) => {
          if (result.confirmationRequired || result.approvalRequired) {
            setConfirmationMessage(
              result.message ?? t('devise.registrations.signed_up_but_unconfirmed'),
            )
          } else {
            void (redirect ? navigate({ href: redirect }) : navigate({ to: '/' }))
          }
        },
      },
    )
  }

  return (
    <div className="mx-auto w-full max-w-md py-8">
      <div className="rounded-xl border border-border/80 bg-card p-6 shadow-xs sm:p-8">
        <h1 className="mb-6 text-center text-2xl font-bold tracking-tight">
          {t('common.forms.auth.sign_up')}
        </h1>

        {confirmationMessage ? (
          <div className="space-y-5 text-center">
            <p role="status" className="text-sm text-foreground">
              {confirmationMessage}
            </p>
            <Button asChild variant="outline" className="w-full">
              <Link to="/login" search={{ redirect }}>
                {t('common.forms.auth.log_in')}
              </Link>
            </Button>
          </div>
        ) : oauthOnly ? (
          <div className="space-y-5">
            <p className="text-center text-sm text-muted-foreground">
              {t('common.forms.auth.oauth_only_info')}
            </p>
            <OAuthButtons providers={oauthProviders} mode="signup" redirect={redirect} />
          </div>
        ) : emailRegistrationBlocked ? (
          <div className="space-y-5">
            <p className="text-center text-sm text-muted-foreground">
              {t('common.forms.auth.email_registration_not_allowed')}
            </p>
            <OAuthButtons providers={oauthProviders} mode="signup" redirect={redirect} />
          </div>
        ) : (
          <div className="space-y-5">
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label htmlFor={fullNameId} className="block text-sm font-medium">
                  {t('common.forms.auth.full_name')}
                </label>
                <Input
                  id={fullNameId}
                  type="text"
                  required
                  autoComplete="name"
                  value={fullName}
                  onChange={(event) => setFullName(event.target.value)}
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor={emailId} className="block text-sm font-medium">
                  {t('common.forms.auth.email')}
                </label>
                <Input
                  id={emailId}
                  type="email"
                  required
                  autoComplete="email"
                  readOnly={hasInvitation && Boolean(initialEmail)}
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                />
              </div>

              <div className="space-y-1.5">
                <div className="flex items-center justify-between gap-2">
                  <label htmlFor={passwordId} className="block text-sm font-medium">
                    {t('common.forms.auth.password')}
                  </label>
                  <span className="text-xs text-muted-foreground">
                    {t('common.forms.auth.password_help', { count: 6 })}
                  </span>
                </div>
                <Input
                  id={passwordId}
                  type="password"
                  required
                  minLength={6}
                  autoComplete="new-password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor={passwordConfirmationId} className="block text-sm font-medium">
                  {t('common.forms.auth.password_confirmation')}
                </label>
                <Input
                  id={passwordConfirmationId}
                  type="password"
                  required
                  minLength={6}
                  autoComplete="new-password"
                  value={passwordConfirmation}
                  onChange={(event) => setPasswordConfirmation(event.target.value)}
                />
              </div>

              <FormError error={register.error} />

              <Button type="submit" className="h-10 w-full" disabled={register.isPending}>
                {t('common.forms.auth.sign_up')}
              </Button>
            </form>

            {!hasInvitation && (
              <OAuthButtons
                providers={oauthProviders}
                mode="signup"
                showDivider
                redirect={redirect}
              />
            )}
          </div>
        )}

        <div className="mt-6 border-t border-border/70 pt-4 text-center text-sm">
          <Link
            to="/login"
            search={{ redirect }}
            className="font-medium text-primary hover:underline"
          >
            {t('common.forms.auth.log_in')}
          </Link>
        </div>
      </div>
    </div>
  )
}
