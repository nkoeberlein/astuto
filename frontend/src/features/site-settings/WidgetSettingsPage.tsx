import { useSuspenseQuery } from '@tanstack/react-query'
import { useState } from 'react'
import type { WidgetSettings } from '@/api/client'
import { useWidgetMutations } from '@/api/mutations'
import { widgetSettingsQuery } from '@/api/queries'
import { CopyButton } from '@/components/CopyButton'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'
import { CheckboxField, SettingsSection } from './fields'

// Code for the customer's site and server (docs/widget.md)
export function widgetSnippet(origin: string) {
  return `<script src="${origin}/widget.js" data-token="VISITOR_TOKEN" defer></script>`
}

export const TOKEN_EXAMPLE = `// Node.js, on your server (npm install jsonwebtoken)
import jwt from 'jsonwebtoken'

const visitorToken = jwt.sign(
  { email: user.email, name: user.name, id: String(user.id) },
  process.env.ASTUTO_WIDGET_SECRET,
  { algorithm: 'HS256', expiresIn: '1h' },
)`

type Draft = Omit<WidgetSettings, 'secret'>

// Site settings › Widget: feedback widget for other sites with visitor sign-in
export function WidgetSettingsPage() {
  const { t } = useI18n()
  const { data: settings } = useSuspenseQuery(widgetSettingsQuery)
  const { save, rotate } = useWidgetMutations()
  const [draft, setDraft] = useState<Draft>({
    enabled: settings.enabled,
    allowedOrigins: settings.allowedOrigins,
    autoCreateUsers: settings.autoCreateUsers,
  })
  const help = (key: string) => t(`site_settings.widget.${key}`)
  const snippet = widgetSnippet(window.location.origin)

  return (
    <div className="space-y-6">
      <SettingsSection title={help('title')}>
        <p className="text-sm text-muted-foreground">{help('intro')}</p>
        <form
          className="space-y-4"
          onSubmit={(event) => {
            event.preventDefault()
            save.mutate(draft)
          }}
        >
          <CheckboxField
            label={help('enabled')}
            checked={draft.enabled}
            onChange={(enabled) => setDraft({ ...draft, enabled })}
          />
          <div className="space-y-1.5">
            <Label htmlFor="widget-origins">{help('allowed_origins')}</Label>
            <Textarea
              id="widget-origins"
              rows={3}
              value={draft.allowedOrigins}
              placeholder="https://app.example.com"
              onChange={(event) => setDraft({ ...draft, allowedOrigins: event.target.value })}
              aria-describedby="widget-origins-help"
              className="font-mono text-sm"
            />
            <p id="widget-origins-help" className="text-xs text-muted-foreground">
              {help('allowed_origins_help')}
            </p>
          </div>
          <CheckboxField
            label={help('auto_create_users')}
            checked={draft.autoCreateUsers}
            onChange={(autoCreateUsers) => setDraft({ ...draft, autoCreateUsers })}
            help={help('auto_create_users_help')}
          />
          <FormError error={save.error} />
          <Button type="submit" disabled={save.isPending}>
            {t('common.buttons.update')}
          </Button>
        </form>
      </SettingsSection>

      <SettingsSection title={help('install_title')}>
        <p className="text-sm text-muted-foreground">{help('install_intro')}</p>
        <pre className="overflow-x-auto rounded bg-muted/60 p-3 font-mono text-xs">{snippet}</pre>
        <CopyButton text={snippet} />

        <p className="pt-2 text-sm text-muted-foreground">{help('token_intro')}</p>
        <div className="flex flex-wrap items-center gap-2">
          <code className="break-all rounded bg-muted/60 px-2 py-1 font-mono text-xs">
            {settings.secret}
          </code>
          <CopyButton text={settings.secret} />
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={rotate.isPending}
            onClick={() => {
              if (window.confirm(help('rotate_confirm'))) rotate.mutate()
            }}
          >
            {help('rotate')}
          </Button>
        </div>
        <FormError error={rotate.error} />
        <pre className="overflow-x-auto rounded bg-muted/60 p-3 font-mono text-xs">
          {TOKEN_EXAMPLE}
        </pre>
        <p className="text-xs text-muted-foreground">{help('token_rules')}</p>
      </SettingsSection>
    </div>
  )
}
