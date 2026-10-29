import { useSuspenseQuery } from '@tanstack/react-query'
import { useBlocker } from '@tanstack/react-router'
import { Mail } from 'lucide-react'
import { useState } from 'react'
import type { GeneralSettings } from '@/api/client'
import { useSendTestEmail, useUpdateGeneralSettings } from '@/api/mutations'
import { boardsQuery, generalSettingsQuery, SORT_OPTIONS, sessionQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'
import { CheckboxField, SelectField, SettingsSection, TextField } from './fields'
import {
  changedFields,
  draftFromSettings,
  formatCustomLinks,
  type GeneralDraft,
  LOCALE_NAMES,
  parseCustomLinks,
} from './general'

// Site settings › General (legacy: /site_settings/general)
export function GeneralSettingsPage() {
  const { data: settings } = useSuspenseQuery(generalSettingsQuery)
  const save = useUpdateGeneralSettings()
  // Remount with fresh state whenever the saved settings change
  return <GeneralForm key={JSON.stringify(settings)} settings={settings} save={save} />
}

function GeneralForm(props: {
  settings: GeneralSettings
  save: ReturnType<typeof useUpdateGeneralSettings>
}) {
  const { settings, save } = props
  const { t } = useI18n()
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const original = draftFromSettings(settings)
  const [draft, setDraft] = useState<GeneralDraft>(original)
  const [linksText, setLinksText] = useState(formatCustomLinks(settings.customLinks))

  const current = { ...draft, customLinks: parseCustomLinks(linksText) }
  const changes = changedFields(original, current)
  const dirty =
    Object.keys(changes).length > 0 || linksText !== formatCustomLinks(settings.customLinks)

  useBlocker({
    shouldBlockFn: () => dirty && !window.confirm(t('common.unsaved_changes')),
    enableBeforeUnload: dirty,
  })

  const set = <K extends keyof GeneralDraft>(key: K, value: GeneralDraft[K]) =>
    setDraft((prev) => ({ ...prev, [key]: value }))
  const label = (model: 'tenant' | 'tenant_setting', field: string) =>
    t(`activerecord.attributes.${model}.${field}`)
  const help = (key: string) => t(`site_settings.general.${key}`)

  return (
    <form
      className="space-y-6"
      onSubmit={(event) => {
        event.preventDefault()
        if (Object.keys(changes).length > 0) save.mutate(changes)
      }}
    >
      <SettingsSection title={t('site_settings.general.title')}>
        <TextField
          label={label('tenant', 'site_name')}
          value={draft.siteName}
          onChange={(value) => set('siteName', value)}
        />
        <TextField
          label={label('tenant', 'site_logo')}
          type="url"
          value={draft.siteLogo ?? ''}
          onChange={(value) => set('siteLogo', value || null)}
          placeholder="https://"
        />
        <TextField
          label={label('tenant', 'site_favicon')}
          type="url"
          value={draft.siteFavicon ?? ''}
          onChange={(value) => set('siteFavicon', value || null)}
          placeholder="https://"
        />
        <SelectField
          label={label('tenant_setting', 'brand_display')}
          value={draft.brandDisplay}
          onChange={(value) => set('brandDisplay', value)}
          options={[
            { value: 'name_and_logo', label: help('brand_setting_both') },
            { value: 'name_only', label: help('brand_setting_name') },
            { value: 'logo_only', label: help('brand_setting_logo') },
            { value: 'no_name_no_logo', label: help('brand_setting_none') },
          ]}
        />
        <SelectField
          label={label('tenant', 'locale')}
          value={draft.locale}
          onChange={(value) => set('locale', value)}
          options={settings.availableLocales.map((locale) => ({
            value: locale,
            label: LOCALE_NAMES[locale] ?? locale,
          }))}
        />
        <CheckboxField
          label={label('tenant_setting', 'use_browser_locale')}
          checked={draft.useBrowserLocale}
          onChange={(value) => set('useBrowserLocale', value)}
          help={help('use_browser_locale_help')}
        />
        <SelectField
          label={label('tenant_setting', 'root_board_id')}
          value={String(draft.rootBoardId)}
          onChange={(value) => set('rootBoardId', Number(value))}
          options={[
            { value: '0', label: t('roadmap.title') },
            ...boards.map((board) => ({ value: String(board.id), label: board.name })),
          ]}
        />
        <SelectField
          label={label('tenant_setting', 'default_post_sorting')}
          value={draft.defaultPostSorting}
          onChange={(value) => set('defaultPostSorting', value)}
          options={SORT_OPTIONS.map((option) => ({
            value: option,
            label: t(`board.sort_by_box.${option}`),
          }))}
          help={help('default_post_sorting_help')}
        />
        {settings.multiTenancy && (
          <TextField
            label={label('tenant', 'custom_domain')}
            value={draft.customDomain ?? ''}
            onChange={(value) => set('customDomain', value || null)}
            help={
              draft.customDomain && draft.customDomain !== settings.customDomain
                ? t('site_settings.general.custom_domain_help', {
                    domain: draft.customDomain,
                    // Any host of this instance works as the CNAME target
                    target: window.location.hostname,
                  })
                : undefined
            }
          />
        )}
      </SettingsSection>

      <SettingsSection title={help('subtitle_privacy')}>
        <CheckboxField
          label={label('tenant_setting', 'is_private')}
          checked={draft.isPrivate}
          onChange={(value) => set('isPrivate', value)}
          help={help('is_private_help')}
        />
        <CheckboxField
          label={label('tenant_setting', 'use_gravatar')}
          checked={draft.useGravatar}
          onChange={(value) => set('useGravatar', value)}
          help={help('use_gravatar_help')}
        />
        <CheckboxField
          label={label('tenant_setting', 'require_two_factor_for_staff')}
          checked={draft.requireTwoFactorForStaff}
          onChange={(value) => set('requireTwoFactorForStaff', value)}
          help={help('require_two_factor_for_staff_help')}
        />
      </SettingsSection>

      <SettingsSection title={help('subtitle_moderation')}>
        <CheckboxField
          label={label('tenant_setting', 'allow_anonymous_feedback')}
          checked={draft.allowAnonymousFeedback}
          onChange={(value) => set('allowAnonymousFeedback', value)}
          help={help('allow_anonymous_feedback_help')}
        />
        <SelectField
          label={label('tenant_setting', 'feedback_approval_policy')}
          value={draft.feedbackApprovalPolicy}
          onChange={(value) => set('feedbackApprovalPolicy', value)}
          options={(
            [
              'anonymous_require_approval',
              'never_require_approval',
              'always_require_approval',
              'new_users_require_approval',
            ] as const
          ).map((policy) => ({ value: policy, label: help(`feedback_approval_policy_${policy}`) }))}
          help={help('feedback_approval_policy_help')}
        />
        {draft.feedbackApprovalPolicy === 'new_users_require_approval' && (
          <TextField
            label={label('tenant_setting', 'trusted_after_posts')}
            type="number"
            value={String(draft.trustedAfterPosts)}
            onChange={(value) => set('trustedAfterPosts', Number(value))}
            help={help('trusted_after_posts_help')}
          />
        )}
      </SettingsSection>

      <SettingsSection title={help('subtitle_authentication')}>
        <CheckboxField
          label={label('tenant_setting', 'login_only_with_oauth')}
          checked={draft.loginOnlyWithOauth}
          onChange={(value) => set('loginOnlyWithOauth', value)}
          help={help('login_only_with_oauth_help')}
        />
      </SettingsSection>

      <SettingsSection title={help('subtitle_header')}>
        <SelectField
          label={label('tenant_setting', 'logo_links_to')}
          value={draft.logoLinksTo}
          onChange={(value) => set('logoLinksTo', value)}
          options={[
            { value: 'root_page', label: help('logo_links_to_root_page') },
            { value: 'custom_url', label: help('logo_links_to_custom_url') },
            { value: 'nothing', label: help('logo_links_to_nothing') },
          ]}
        />
        {draft.logoLinksTo === 'custom_url' && (
          <TextField
            label={label('tenant_setting', 'logo_custom_url')}
            type="url"
            value={draft.logoCustomUrl ?? ''}
            onChange={(value) => set('logoCustomUrl', value || null)}
            placeholder="https://"
          />
        )}
        <CheckboxField
          label={label('tenant_setting', 'roadmap_enabled')}
          checked={draft.roadmapEnabled}
          onChange={(value) => set('roadmapEnabled', value)}
          help={help('roadmap_enabled_help')}
        />
        {draft.roadmapEnabled && (
          <CheckboxField
            label={label('tenant_setting', 'show_roadmap_in_header')}
            checked={draft.showRoadmapInHeader}
            onChange={(value) => set('showRoadmapInHeader', value)}
          />
        )}
        <SelectField
          label={label('tenant_setting', 'collapse_boards_in_header')}
          value={draft.collapseBoardsInHeader}
          onChange={(value) => set('collapseBoardsInHeader', value)}
          options={[
            { value: 'no_collapse', label: help('collapse_boards_in_header_no_collapse') },
            { value: 'always_collapse', label: help('collapse_boards_in_header_always_collapse') },
          ]}
        />
        <div className="space-y-1.5">
          <Label htmlFor="custom-links">{label('tenant_setting', 'custom_links')}</Label>
          <Textarea
            id="custom-links"
            rows={3}
            value={linksText}
            onChange={(event) => setLinksText(event.target.value)}
            placeholder="Docs|https://example.com/docs"
            aria-describedby="custom-links-help"
            className="font-mono text-sm"
          />
          <p id="custom-links-help" className="text-sm text-muted-foreground">
            {help('custom_links_help')}
          </p>
        </div>
      </SettingsSection>

      <SettingsSection title={help('subtitle_mail')}>
        <TextField
          label={label('tenant_setting', 'mail_logo_size')}
          type="number"
          value={String(draft.mailLogoSize)}
          onChange={(value) => set('mailLogoSize', Number(value))}
          help={help('mail_logo_size_help')}
        />
        <TestEmailButton />
      </SettingsSection>

      <SettingsSection title={help('subtitle_visibility')}>
        <CheckboxField
          label={label('tenant_setting', 'show_vote_count')}
          checked={draft.showVoteCount}
          onChange={(value) => set('showVoteCount', value)}
          help={help('show_vote_count_help')}
        />
        <CheckboxField
          label={label('tenant_setting', 'show_vote_button_in_board')}
          checked={draft.showVoteButtonInBoard}
          onChange={(value) => set('showVoteButtonInBoard', value)}
          help={help('show_vote_button_in_board_help')}
        />
        <CheckboxField
          label={label('tenant_setting', 'hide_unused_statuses_in_filter_by_status')}
          checked={draft.hideUnusedStatusesInFilterByStatus}
          onChange={(value) => set('hideUnusedStatusesInFilterByStatus', value)}
          help={help('hide_unused_statuses_in_filter_by_status_help')}
        />
        <CheckboxField
          label={label('tenant_setting', 'show_powered_by')}
          checked={draft.showPoweredBy}
          onChange={(value) => set('showPoweredBy', value)}
        />
      </SettingsSection>

      {/* Stays in view while scrolling through the sections */}
      <div className="sticky bottom-0 -mx-1 flex flex-wrap items-center gap-3 border-t bg-background/90 px-1 py-3 backdrop-blur">
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

// Checks the email configuration without saving anything; outside the form, so it never submits it
function TestEmailButton() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const send = useSendTestEmail()
  const email = session.user?.email ?? ''

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-3">
        <Button
          type="button"
          variant="outline"
          disabled={send.isPending}
          onClick={() => send.mutate()}
        >
          <Mail className="size-4" aria-hidden />
          {t('site_settings.general.test_email')}
        </Button>
        <p className="text-sm text-muted-foreground">
          {t('site_settings.general.test_email_help', { email })}
        </p>
      </div>
      <p className="text-sm" aria-live="polite">
        {send.data &&
          t('site_settings.general.test_email_sent', {
            email: send.data.sentTo,
            method: send.data.deliveryMethod,
            from: send.data.from,
          })}
      </p>
      <FormError error={send.error} />
    </div>
  )
}
