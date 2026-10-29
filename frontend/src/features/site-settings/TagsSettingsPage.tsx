import { useSuspenseQuery } from '@tanstack/react-query'
import type { Tag } from '@/api/client'
import { useTagMutations } from '@/api/mutations'
import { tagsQuery } from '@/api/queries'
import { useI18n } from '@/lib/i18n'
import { TextField } from './fields'
import { ListEditor } from './ListEditor'
import { ColorField } from './PostStatusesSettingsPage'

type TagDraft = { name: string; color: string }

// Site settings › Tags (#171): labels moderators put on posts, visitors filter by
export function TagsSettingsPage() {
  const { t } = useI18n()
  const { data: tags } = useSuspenseQuery(tagsQuery)
  const { create, update, remove, reorder } = useTagMutations()
  const input = (draft: TagDraft) => ({ ...draft, name: draft.name.trim() })

  return (
    <ListEditor<Tag, TagDraft>
      title={t('site_settings.tags.title')}
      items={tags}
      emptyText={t('site_settings.tags.empty')}
      itemName={(tag) => tag.name}
      renderItem={(tag) => (
        <p className="flex items-center gap-2 font-medium">
          <span
            className="size-3 shrink-0 rounded-full"
            style={{ backgroundColor: tag.color }}
            aria-hidden
          />
          <span className="truncate">{tag.name}</span>
        </p>
      )}
      newDraft={() => ({ name: '', color: '#64748b' })}
      draftFor={(tag) => ({ name: tag.name, color: tag.color })}
      renderForm={(draft, setDraft) => (
        <>
          <TextField
            label={t('site_settings.tags.form.name')}
            value={draft.name}
            onChange={(name) => setDraft({ ...draft, name })}
          />
          <ColorField
            label={t('site_settings.tags.form.color')}
            value={draft.color}
            onChange={(color) => setDraft({ ...draft, color })}
          />
        </>
      )}
      onCreate={(draft) => create.mutateAsync(input(draft))}
      onUpdate={(tag, draft) => update.mutateAsync({ id: tag.id, ...input(draft) })}
      onDelete={(tag) => remove.mutateAsync(tag.id)}
      onReorder={(ids) => reorder.mutate(ids)}
      deleteConfirmation={t('site_settings.tags.delete_confirmation')}
      error={create.error ?? update.error ?? remove.error ?? reorder.error}
      onDismissError={() =>
        [create, update, remove, reorder].forEach((m) => {
          m.reset()
        })
      }
    />
  )
}
