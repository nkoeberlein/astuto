import { useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { sessionQuery } from '@/api/queries'
import { useI18n } from '@/lib/i18n'

// Staff of a space that requires two-factor authentication see this until they set it up
export function TwoFactorSetupBanner() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  if (!session.user?.twoFactorSetupRequired) return null

  return (
    <div
      role="status"
      className="border-b border-amber-500/40 bg-amber-500/10 px-4 py-2 text-center text-sm"
    >
      {t('two_factor.required_notice')}{' '}
      <Link to="/profile" className="font-medium underline">
        {t('two_factor.set_up')}
      </Link>
    </div>
  )
}
