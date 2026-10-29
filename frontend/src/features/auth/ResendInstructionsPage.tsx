import { Link } from '@tanstack/react-router'
import { type FormEvent, useId, useState } from 'react'
import { useResendInstructions } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'

const TITLES = {
  confirmation: 'common.forms.auth.resend_confirmation_instructions',
  unlock: 'common.forms.auth.resend_unlock_instructions',
} as const

// Asks for the email confirmation or account unlock link again (the links in the emails
// themselves still go to /users/confirmation and /users/unlock, which redirect back here on errors)
export function ResendInstructionsPage({ kind }: { kind: 'confirmation' | 'unlock' }) {
  const { t } = useI18n()
  const resend = useResendInstructions(kind)
  const emailId = useId()

  const [email, setEmail] = useState('')
  const [sentMessage, setSentMessage] = useState<string | null>(null)

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resend.mutate(
      { email: email.trim() },
      { onSuccess: (result) => setSentMessage(result.message) },
    )
  }

  return (
    <div className="mx-auto w-full max-w-md py-8">
      <div className="rounded-xl border border-border/80 bg-card p-6 shadow-xs sm:p-8">
        <h1 className="mb-6 text-center text-2xl font-bold tracking-tight">{t(TITLES[kind])}</h1>

        {sentMessage ? (
          <p role="status" className="text-center text-sm text-foreground">
            {sentMessage}
          </p>
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

            <FormError error={resend.error} />

            <Button type="submit" className="h-10 w-full" disabled={resend.isPending}>
              {t(TITLES[kind])}
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
