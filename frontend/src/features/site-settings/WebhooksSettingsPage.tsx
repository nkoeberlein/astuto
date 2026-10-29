import { useSuspenseQuery } from '@tanstack/react-query'
import { BookOpen, Eye, FlaskConical, History, KeyRound, Pencil, Plus, Trash2 } from 'lucide-react'
import { type FormEvent, useRef, useState } from 'react'
import type { Webhook, WebhookDelivery, WebhookInput } from '@/api/client'
import { useWebhookMutations } from '@/api/mutations'
import { webhooksQuery, webhookTemplatesQuery, webhookVariablesQuery } from '@/api/queries'
import { CopyButton } from '@/components/CopyButton'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'
import { projectDocsUrl } from '@/lib/project'
import { CheckboxField, SelectField, SettingsSection, TextField } from './fields'
import { HeaderRows } from './HeaderRows'
import { DeliveryStatus, WebhookDeliveries } from './WebhookDeliveries'

// Product names, not translated
const TEMPLATE_SERVICES = [
  ['slack', 'Slack'],
  ['discord', 'Discord'],
  ['teams', 'Microsoft Teams'],
] as const

const TRIGGERS: Webhook['trigger'][] = [
  'new_post',
  'new_post_pending_approval',
  'delete_post',
  'post_status_change',
  'new_comment',
  'new_vote',
  'new_user',
]
const METHODS: Webhook['httpMethod'][] = ['post', 'put', 'patch', 'delete']

// Site settings › Webhooks (legacy: /site_settings/webhooks)
export function WebhooksSettingsPage() {
  const { t } = useI18n()
  const { data: webhooks } = useSuspenseQuery(webhooksQuery)
  const { create, update, remove, test } = useWebhookMutations()
  const [editing, setEditing] = useState<number | 'new' | null>(null)
  const [logFor, setLogFor] = useState<number | null>(null)
  const error = create.error ?? update.error ?? remove.error

  const open = (id: number | 'new' | null) => {
    for (const mutation of [create, update, remove, test]) mutation.reset()
    setEditing(id)
  }

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold tracking-tight">{t('site_settings.webhooks.title')}</h2>
      <a
        href={projectDocsUrl('webhooks.md')}
        target="_blank"
        rel="noopener"
        className="inline-flex items-center gap-1.5 text-sm text-primary underline-offset-4 hover:underline"
      >
        <BookOpen className="size-4" aria-hidden />
        {t('site_settings.webhooks.learn_more')}
      </a>
      <FormError error={error} />

      {webhooks.length === 0 && editing !== 'new' && (
        <p className="rounded-lg border border-dashed p-6 text-center text-muted-foreground">
          {t('site_settings.webhooks.empty')}
        </p>
      )}
      <ul className="space-y-3">
        {webhooks.map((webhook) =>
          editing === webhook.id ? (
            <li key={webhook.id} className="rounded-xl border bg-card p-4 shadow-2xs">
              <h3 className="mb-4 font-semibold">{t('site_settings.webhooks.form.title_edit')}</h3>
              <WebhookForm
                webhook={webhook}
                onSubmit={(input) =>
                  update.mutateAsync({ id: webhook.id, ...input }).then(() => open(null))
                }
                onCancel={() => open(null)}
              />
            </li>
          ) : (
            <li key={webhook.id} className="space-y-3 rounded-xl border bg-card p-4 shadow-2xs">
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">{webhook.name}</p>
                  <p className="truncate text-sm text-muted-foreground">
                    {t(`site_settings.webhooks.triggers.${webhook.trigger}`)} ·{' '}
                    <span className="font-mono">{webhook.httpMethod.toUpperCase()}</span>
                    {webhook.description && ` · ${webhook.description}`}
                  </p>
                  {webhook.lastDelivery && (
                    <DeliveryStatus delivery={webhook.lastDelivery as WebhookDelivery} />
                  )}
                </div>
                <div className="flex flex-wrap items-center gap-2">
                  <span className="flex items-center gap-2 text-sm">
                    <Checkbox
                      id={`webhook-enabled-${webhook.id}`}
                      checked={webhook.isEnabled}
                      onCheckedChange={(checked) =>
                        update.mutate({ id: webhook.id, isEnabled: checked === true })
                      }
                    />
                    <label htmlFor={`webhook-enabled-${webhook.id}`}>{t('common.enabled')}</label>
                  </span>
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    disabled={test.isPending}
                    onClick={() => test.mutate(webhook.id)}
                  >
                    <FlaskConical className="size-4" aria-hidden />
                    {t('common.buttons.test')}
                  </Button>
                  <Button
                    type="button"
                    size="sm"
                    variant="ghost"
                    aria-expanded={logFor === webhook.id}
                    onClick={() => setLogFor(logFor === webhook.id ? null : webhook.id)}
                  >
                    <History className="size-4" aria-hidden />
                    {t('site_settings.webhooks.deliveries.show')}
                  </Button>
                  <Button
                    type="button"
                    size="icon"
                    variant="ghost"
                    className="size-8 text-muted-foreground"
                    aria-label={`${webhook.name}: ${t('common.buttons.edit')}`}
                    title={t('common.buttons.edit')}
                    onClick={() => open(webhook.id)}
                  >
                    <Pencil className="size-4" aria-hidden />
                  </Button>
                  <Button
                    type="button"
                    size="icon"
                    variant="ghost"
                    className="size-8 text-destructive hover:text-destructive"
                    aria-label={`${webhook.name}: ${t('common.buttons.delete')}`}
                    title={t('common.buttons.delete')}
                    onClick={() => {
                      if (window.confirm(t('common.confirmation'))) remove.mutate(webhook.id)
                    }}
                  >
                    <Trash2 className="size-4" aria-hidden />
                  </Button>
                </div>
              </div>
              {test.variables === webhook.id && (test.data || test.error) && (
                <TestResult status={test.data?.status} body={test.data?.body} error={test.error} />
              )}
              {logFor === webhook.id && <WebhookDeliveries webhookId={webhook.id} />}
            </li>
          ),
        )}
      </ul>

      {editing === 'new' ? (
        <div className="rounded-xl border bg-card p-4 shadow-2xs">
          <h3 className="mb-4 font-semibold">{t('site_settings.webhooks.form.title_new')}</h3>
          <WebhookForm
            onSubmit={(input) => create.mutateAsync(input).then(() => open(null))}
            onCancel={() => open(null)}
          />
        </div>
      ) : (
        <Button type="button" variant="outline" onClick={() => open('new')}>
          <Plus className="size-4" aria-hidden />
          {t('common.buttons.new')}
        </Button>
      )}
    </div>
  )
}

function TestResult(props: { status?: number; body?: string; error: Error | null }) {
  const { t } = useI18n()
  if (props.error) return <FormError error={props.error} />
  const ok = props.status !== undefined && props.status >= 200 && props.status < 300
  return (
    <div className="space-y-1 rounded-lg bg-muted/60 p-3 text-sm">
      <p className="font-medium">
        {t('site_settings.webhooks.test_page.title')}:{' '}
        <span className={ok ? 'text-green-700 dark:text-green-400' : 'text-destructive'}>
          HTTP {props.status}
        </span>
      </p>
      {props.body && (
        <pre className="max-h-40 overflow-auto whitespace-pre-wrap break-all font-mono text-xs">
          {props.body}
        </pre>
      )}
    </div>
  )
}

type Draft = Required<{ [K in keyof WebhookInput]: NonNullable<WebhookInput[K]> }>

function WebhookForm(props: {
  webhook?: Webhook
  onSubmit: (input: WebhookInput) => Promise<unknown>
  onCancel: () => void
}) {
  const { t } = useI18n()
  const { data: variables } = useSuspenseQuery(webhookVariablesQuery)
  const { data: templates } = useSuspenseQuery(webhookTemplatesQuery)
  const { preview } = useWebhookMutations()
  const w = props.webhook
  const [draft, setDraft] = useState<Draft>({
    name: w?.name ?? '',
    description: w?.description ?? '',
    isEnabled: w?.isEnabled ?? false,
    trigger: w?.trigger ?? 'new_post',
    httpMethod: w?.httpMethod ?? 'post',
    url: w?.url ?? '',
    httpBody: w?.httpBody ?? '',
    httpHeaders: w?.httpHeaders.length ? w.httpHeaders : [{ key: '', value: '' }],
  })
  const [busy, setBusy] = useState(false)
  const bodyRef = useRef<HTMLTextAreaElement>(null)

  // Inserts {{ variable }} at the cursor of the body field
  const insertVariable = (variable: string) => {
    const field = bodyRef.current
    const text = `{{ ${variable} }}`
    const start = field?.selectionStart ?? draft.httpBody.length
    const end = field?.selectionEnd ?? start
    setDraft({
      ...draft,
      httpBody: draft.httpBody.slice(0, start) + text + draft.httpBody.slice(end),
    })
    requestAnimationFrame(() => {
      field?.focus()
      field?.setSelectionRange(start + text.length, start + text.length)
    })
  }

  // Chat tool template: POST with a JSON body for the current trigger
  const applyTemplate = (service: keyof typeof templates) => {
    const body = templates[service][draft.trigger]
    if (!body) return
    if (
      draft.httpBody.trim() &&
      !window.confirm(t('site_settings.webhooks.form.templates_confirm'))
    )
      return
    const headers = draft.httpHeaders.filter(
      (header) => header.key.trim() && header.key.toLowerCase() !== 'content-type',
    )
    setDraft({
      ...draft,
      httpMethod: 'post',
      httpBody: body,
      httpHeaders: [{ key: 'Content-Type', value: 'application/json' }, ...headers],
    })
  }

  const submit = (event: FormEvent) => {
    event.preventDefault()
    setBusy(true)
    props
      .onSubmit({
        ...draft,
        description: draft.description || null,
        httpBody: draft.httpBody || null,
      })
      .catch(() => undefined)
      .finally(() => setBusy(false))
  }

  return (
    <form className="space-y-4" onSubmit={submit}>
      <TextField
        label={t('activerecord.attributes.webhook.name')}
        value={draft.name}
        onChange={(name) => setDraft({ ...draft, name })}
      />
      <TextField
        label={t('activerecord.attributes.webhook.description')}
        value={draft.description}
        onChange={(description) => setDraft({ ...draft, description })}
      />
      <CheckboxField
        label={t('activerecord.attributes.webhook.is_enabled')}
        checked={draft.isEnabled}
        onChange={(isEnabled) => setDraft({ ...draft, isEnabled })}
      />
      <SelectField
        label={t('activerecord.attributes.webhook.trigger')}
        value={draft.trigger}
        onChange={(trigger) => setDraft({ ...draft, trigger })}
        options={TRIGGERS.map((trigger) => ({
          value: trigger,
          label: t(`site_settings.webhooks.triggers.${trigger}`),
        }))}
      />
      <SelectField
        label={t('activerecord.attributes.webhook.http_method')}
        value={draft.httpMethod}
        onChange={(httpMethod) => setDraft({ ...draft, httpMethod })}
        options={METHODS.map((method) => ({ value: method, label: method.toUpperCase() }))}
      />
      <TextField
        label={t('activerecord.attributes.webhook.url')}
        value={draft.url}
        onChange={(url) => setDraft({ ...draft, url })}
        placeholder="https://"
      />

      <HeaderRows
        legend={t('activerecord.attributes.webhook.http_headers')}
        rows={draft.httpHeaders}
        onChange={(httpHeaders) => setDraft({ ...draft, httpHeaders })}
        keyPlaceholder="Authorization"
        valuePlaceholder="Bearer …"
      />

      <div className="space-y-1.5">
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <span className="text-muted-foreground">
            {t('site_settings.webhooks.form.templates_label')}
          </span>
          {TEMPLATE_SERVICES.map(([service, name]) => (
            <Button
              key={service}
              type="button"
              size="sm"
              variant="outline"
              onClick={() => applyTemplate(service)}
            >
              {name}
            </Button>
          ))}
        </div>
        <p className="text-xs text-muted-foreground">
          {t('site_settings.webhooks.form.templates_help')}
        </p>
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="webhook-body">{t('activerecord.attributes.webhook.http_body')}</Label>
        <Textarea
          id="webhook-body"
          ref={bodyRef}
          rows={8}
          value={draft.httpBody}
          onChange={(event) => setDraft({ ...draft, httpBody: event.target.value })}
          spellCheck={false}
          placeholder={'{ "text": "{{ post.title | escape_json }}" }'}
          className="font-mono text-sm"
        />
        <fieldset className="flex flex-wrap gap-1.5">
          <legend className="sr-only">
            {t('site_settings.webhooks.form.template_variables_selector_placeholder')}
          </legend>
          {(variables[draft.trigger] ?? []).map((variable) => (
            <button
              key={variable}
              type="button"
              onClick={() => insertVariable(variable)}
              className="rounded border bg-muted/50 px-1.5 py-0.5 font-mono text-xs text-muted-foreground hover:bg-accent hover:text-foreground"
            >
              {variable}
            </button>
          ))}
        </fieldset>
      </div>

      {w && <SigningSecret webhook={w} />}

      <SettingsSection title={t('common.buttons.preview')}>
        <Button
          type="button"
          size="sm"
          variant="outline"
          disabled={preview.isPending}
          onClick={() =>
            preview.mutate({
              trigger: draft.trigger,
              url: draft.url,
              httpBody: draft.httpBody || null,
            })
          }
        >
          <Eye className="size-4" aria-hidden />
          {t('common.buttons.preview')}
        </Button>
        {preview.error ? (
          <FormError error={preview.error} />
        ) : (
          preview.data && (
            <div className="space-y-2 text-sm">
              <p className="break-all font-mono text-xs">{preview.data.url}</p>
              {preview.data.body && (
                <pre className="max-h-60 overflow-auto rounded bg-muted/60 p-2 font-mono text-xs whitespace-pre-wrap">
                  {prettyJson(preview.data.body)}
                </pre>
              )}
            </div>
          )
        )}
      </SettingsSection>

      <div className="flex gap-2">
        <Button type="submit" disabled={busy}>
          {w ? t('common.buttons.update') : t('common.buttons.create')}
        </Button>
        <Button type="button" variant="ghost" onClick={props.onCancel}>
          {t('common.buttons.cancel')}
        </Button>
      </div>
    </form>
  )
}

function prettyJson(text: string): string {
  try {
    return JSON.stringify(JSON.parse(text), null, 2)
  } catch {
    return text
  }
}

// HMAC secret of the X-Astuto-Signature header: shown to admins, copied, or replaced
function SigningSecret({ webhook }: { webhook: Webhook }) {
  const { t } = useI18n()
  const { rotateSecret } = useWebhookMutations()
  const secret = rotateSecret.data?.signingSecret ?? webhook.signingSecret

  return (
    <SettingsSection title={t('site_settings.webhooks.signing.title')}>
      <code className="block break-all rounded bg-muted p-2 font-mono text-xs">{secret}</code>
      <div className="flex flex-wrap gap-2">
        <CopyButton text={secret} />
        <Button
          type="button"
          size="sm"
          variant="outline"
          disabled={rotateSecret.isPending}
          onClick={() => {
            if (window.confirm(t('site_settings.webhooks.signing.rotate_confirmation'))) {
              rotateSecret.mutate(webhook.id)
            }
          }}
        >
          <KeyRound className="size-4" aria-hidden />
          {t('site_settings.webhooks.signing.rotate')}
        </Button>
      </div>
      <p className="text-sm text-muted-foreground">{t('site_settings.webhooks.signing.help')}</p>
      <FormError error={rotateSecret.error} />
    </SettingsSection>
  )
}
