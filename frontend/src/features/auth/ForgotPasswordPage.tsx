import { Link } from '@tanstack/react-router'
import { type FormEvent, useId, useState } from 'react'
import { useForgotPassword } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'

export function ForgotPasswordPage() {
  const { t } = useI18n()
  const forgotPassword = useForgotPassword()
  const emailId = useId()

  const [email, setEmail] = useState('')
  const [sentMessage, setSentMessage] = useState<string | null>(null)

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    forgotPassword.mutate(
      { email: email.trim() },
      {
        onSuccess: (result) => {
          setSentMessage(result.message)
        },
      },
    )
  }

  return (
    <div className="mx-auto w-full max-w-md py-8">
      <div className="rounded-xl border border-border/80 bg-card p-6 shadow-xs sm:p-8">
        <h1 className="mb-6 text-center text-2xl font-bold tracking-tight">
          {t('common.forms.auth.forgot_password')}
        </h1>

        {sentMessage ? (
          <div className="space-y-5 text-center">
            <p role="status" className="text-sm text-foreground">
              {sentMessage}
            </p>
            <Button asChild variant="outline" className="w-full">
              <Link to="/login">{t('common.forms.auth.log_in')}</Link>
            </Button>
          </div>
        ) : (
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

            <FormError error={forgotPassword.error} />

            <Button type="submit" className="h-10 w-full" disabled={forgotPassword.isPending}>
              {t('common.forms.auth.send_reset_password_instructions')}
            </Button>
          </form>
        )}

        <div className="mt-6 border-t border-border/70 pt-4 text-center text-sm">
          <Link to="/login" className="font-medium text-primary hover:underline">
            {t('common.forms.auth.log_in')}
          </Link>
        </div>
      </div>
    </div>
  )
}
