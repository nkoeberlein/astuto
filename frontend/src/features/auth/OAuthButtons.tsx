import type { OAuthProvider } from '@/api/client'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'
import { oauthStartUrl } from './redirect'

export function OAuthButtons({
  providers,
  mode,
  showDivider = false,
  redirect,
}: {
  providers: OAuthProvider[]
  mode: 'login' | 'signup'
  showDivider?: boolean
  // Page to return to after the OAuth sign-in (path without basepath)
  redirect?: string
}) {
  const { t } = useI18n()

  if (providers.length === 0) return null

  const labelKey =
    mode === 'signup' ? 'common.forms.auth.sign_up_with' : 'common.forms.auth.log_in_with'

  return (
    <div className="space-y-4">
      {showDivider && (
        <div className="relative flex items-center py-1">
          <div className="grow border-t border-border/70" />
          <span className="mx-3 shrink-0 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            {t('common.words.or')}
          </span>
          <div className="grow border-t border-border/70" />
        </div>
      )}

      <div className="flex flex-col gap-2.5">
        {providers.map((provider) => (
          <Button
            key={provider.id}
            asChild
            variant="outline"
            className="h-10 w-full justify-center gap-2.5 font-medium"
          >
            <a href={oauthStartUrl(provider.startUrl, redirect)}>
              {provider.logo && (
                <img src={provider.logo} alt="" className="size-4 shrink-0 object-contain" />
              )}
              <span>{t(labelKey, { o_auth: provider.name })}</span>
            </a>
          </Button>
        ))}
      </div>
    </div>
  )
}
