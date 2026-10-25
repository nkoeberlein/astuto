import { Link, useNavigate } from '@tanstack/react-router'
import { type FormEvent, useId, useState } from 'react'
import { useResetPassword } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'

export function ResetPasswordPage({ resetPasswordToken }: { resetPasswordToken: string }) {
  const { t } = useI18n()
  const navigate = useNavigate()
  const resetPassword = useResetPassword()

  const passwordId = useId()
  const passwordConfirmationId = useId()

  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetPassword.mutate(
      {
        resetPasswordToken,
        password,
        passwordConfirmation,
      },
      {
        onSuccess: (result) => {
          void navigate({ to: result.session.user ? '/' : '/login' })
        },
      },
    )
  }

  return (
    <div className="mx-auto w-full max-w-md py-8">
      <div className="rounded-xl border border-border/80 bg-card p-6 shadow-xs sm:p-8">
        <h1 className="mb-6 text-center text-2xl font-bold tracking-tight">
          {t('common.forms.auth.change_password')}
        </h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <div className="flex items-center justify-between gap-2">
              <label htmlFor={passwordId} className="block text-sm font-medium">
                {t('common.forms.auth.new_password')}
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
              {t('common.forms.auth.new_password_confirmation')}
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

          <FormError error={resetPassword.error} />

          <Button type="submit" className="h-10 w-full" disabled={resetPassword.isPending}>
            {t('common.forms.auth.change_password')}
          </Button>
        </form>

        <div className="mt-6 border-t border-border/70 pt-4 text-center text-sm">
          <Link to="/login" className="font-medium text-primary hover:underline">
            {t('common.forms.auth.log_in')}
          </Link>
        </div>
      </div>
    </div>
  )
}
