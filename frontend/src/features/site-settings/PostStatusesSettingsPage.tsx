import { useSuspenseQuery } from '@tanstack/react-query'
import { useId } from 'react'
import type { PostStatus } from '@/api/client'
import { usePostStatusMutations } from '@/api/mutations'
import { postStatusesQuery } from '@/api/queries'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useI18n } from '@/lib/i18n'
import { CheckboxField, TextField } from './fields'
import { ListEditor } from './ListEditor'

type StatusDraft = { name: string; color: string; showInRoadmap: boolean }

// Site settings › Statuses (legacy: /site_settings/post_statuses)
export function PostStatusesSettingsPage() {
  const { t } = useI18n()
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const { create, update, remove, reorder } = usePostStatusMutations()

  const input = (draft: StatusDraft) => ({ ...draft, name: draft.name.trim() })

  return (
    <ListEditor<PostStatus, StatusDraft>
      title={t('site_settings.post_statuses.title')}
      items={statuses}
      emptyText={t('site_settings.post_statuses.empty')}
      itemName={(status) => status.name}
      renderItem={(status) => (
        <p className="flex items-center gap-2 font-medium">
          <span
            className="size-3 shrink-0 rounded-full"
            style={{ backgroundColor: status.color }}
            aria-hidden
          />
          <span className="truncate">{status.name}</span>
          {status.showInRoadmap && (
            <span className="rounded-full bg-muted px-2 py-0.5 text-xs font-normal text-muted-foreground">
              {t('roadmap.title')}
            </span>
          )}
        </p>
      )}
      newDraft={() => ({ name: '', color: '#0077cc', showInRoadmap: true })}
      draftFor={(status) => ({
        name: status.name,
        color: status.color,
        showInRoadmap: status.showInRoadmap,
      })}
      renderForm={(draft, setDraft) => (
        <>
          <TextField
            label={t('site_settings.post_statuses.form.name')}
            value={draft.name}
            onChange={(name) => setDraft({ ...draft, name })}
          />
          <ColorField
            label={t('activerecord.attributes.post_status.color')}
            value={draft.color}
            onChange={(color) => setDraft({ ...draft, color })}
          />
          <CheckboxField
            label={t('activerecord.attributes.post_status.show_in_roadmap')}
            checked={draft.showInRoadmap}
            onChange={(showInRoadmap) => setDraft({ ...draft, showInRoadmap })}
          />
        </>
      )}
      onCreate={(draft) => create.mutateAsync(input(draft))}
      onUpdate={(status, draft) => update.mutateAsync({ id: status.id, ...input(draft) })}
      onDelete={(status) => remove.mutateAsync(status.id)}
      onReorder={(ids) => reorder.mutate(ids)}
      deleteConfirmation={t('common.confirmation')}
      error={create.error ?? update.error ?? remove.error ?? reorder.error}
      onDismissError={() =>
        [create, update, remove, reorder].forEach((m) => {
          m.reset()
        })
      }
    />
  )
}

// Color picker plus hex text field (the picker alone is hard to use with a keyboard)
function ColorField(props: { label: string; value: string; onChange: (value: string) => void }) {
  const id = useId()
  return (
    <div className="space-y-1.5">
      <Label htmlFor={id}>{props.label}</Label>
      <div className="flex items-center gap-2">
        <input
          type="color"
          value={/^#[0-9a-f]{6}$/i.test(props.value) ? props.value : '#000000'}
          onChange={(event) => props.onChange(event.target.value)}
          aria-label={props.label}
          className="h-9 w-12 cursor-pointer rounded-md border bg-transparent p-1"
        />
        <Input
          id={id}
          value={props.value}
          onChange={(event) => props.onChange(event.target.value)}
          className="w-32 font-mono"
          maxLength={7}
        />
      </div>
    </div>
  )
}
