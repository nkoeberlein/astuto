import { useSuspenseQuery } from '@tanstack/react-query'
import { useBlocker } from '@tanstack/react-router'
import { BookOpen } from 'lucide-react'
import { useState } from 'react'
import { useUpdateGeneralSettings } from '@/api/mutations'
import { generalSettingsQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { escapeCustomCss } from '@/lib/custom-css'
import { useI18n } from '@/lib/i18n'
import { projectDocsUrl } from '@/lib/project'

// Site settings › Appearance (legacy: /site_settings/appearance): custom CSS with live preview
export function AppearanceSettingsPage() {
  const { t } = useI18n()
  const { data: settings } = useSuspenseQuery(generalSettingsQuery)
  const save = useUpdateGeneralSettings()
  const saved = settings.customCss ?? ''
  const [css, setCss] = useState(saved)
  const dirty = css !== saved

  useBlocker({
    shouldBlockFn: () => dirty && !window.confirm(t('common.unsaved_changes')),
    enableBeforeUnload: dirty,
  })

  return (
    <form
      className="space-y-4"
      onSubmit={(event) => {
        event.preventDefault()
        save.mutate({ customCss: css })
      }}
    >
      {/* Preview: comes after the saved CSS of the layout, so the draft wins */}
      {dirty && <style data-astuto-custom-css-preview>{escapeCustomCss(css)}</style>}

      <h2 className="text-xl font-semibold tracking-tight">
        {t('site_settings.appearance.title')}
      </h2>
      <a
        href={projectDocsUrl('appearance.md')}
        target="_blank"
        rel="noopener"
        className="inline-flex items-center gap-1.5 text-sm text-primary underline-offset-4 hover:underline"
      >
        <BookOpen className="size-4" aria-hidden />
        {t('site_settings.appearance.learn_more')}
      </a>

      <div className="space-y-1.5">
        <Label htmlFor="custom-css">{t('activerecord.attributes.tenant_setting.custom_css')}</Label>
        <Textarea
          id="custom-css"
          rows={16}
          value={css}
          onChange={(event) => setCss(event.target.value)}
          spellCheck={false}
          className="font-mono text-sm"
          placeholder=":root { --primary: oklch(0.55 0.2 260); }"
        />
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <Button type="submit" disabled={!dirty || save.isPending}>
          {t('common.buttons.update')}
        </Button>
        <span className="text-sm text-muted-foreground" aria-live="polite">
          {save.isPending
            ? t('common.loading')
            : dirty
              ? t('site_settings.info_box.dirty')
              : save.isSuccess
                ? t('site_settings.info_box.up_to_date')
                : null}
        </span>
        <FormError error={save.error} />
      </div>
    </form>
  )
}
