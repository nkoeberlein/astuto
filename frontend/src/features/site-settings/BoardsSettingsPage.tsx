import { useSuspenseQuery } from '@tanstack/react-query'
import type { Board } from '@/api/client'
import { useBoardMutations } from '@/api/mutations'
import { boardsQuery } from '@/api/queries'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'
import { excerpt } from '@/lib/text'
import { SelectField, TextField } from './fields'
import { ListEditor } from './ListEditor'

type Visibility = Board['visibility']
type BoardDraft = { name: string; slug: string; description: string; visibility: Visibility }

const VISIBILITIES: Visibility[] = ['everyone', 'signed_in', 'staff']

// Site settings › Boards (legacy: /site_settings/boards)
export function BoardsSettingsPage() {
  const { t } = useI18n()
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const { create, update, remove, reorder } = useBoardMutations()

  const input = (draft: BoardDraft) => ({
    name: draft.name.trim(),
    slug: draft.slug.trim() || null,
    description: draft.description.trim() || null,
    visibility: draft.visibility,
  })

  return (
    <ListEditor<Board, BoardDraft>
      title={t('site_settings.boards.title')}
      items={boards}
      emptyText={t('site_settings.boards.empty')}
      itemName={(board) => board.name}
      renderItem={(board) => (
        <>
          <p className="truncate font-medium">{board.name}</p>
          <p className="truncate text-sm text-muted-foreground">
            /boards/{board.slug}
            {board.description && ` · ${excerpt(board.description, 120)}`}
          </p>
          {board.visibility !== 'everyone' && (
            <p className="text-xs text-muted-foreground">
              {t(`site_settings.boards.visibility.${board.visibility}`)}
            </p>
          )}
        </>
      )}
      newDraft={() => ({ name: '', slug: '', description: '', visibility: 'everyone' })}
      draftFor={(board) => ({
        name: board.name,
        slug: board.slug,
        description: board.description ?? '',
        visibility: board.visibility,
      })}
      renderForm={(draft, setDraft) => (
        <>
          <TextField
            label={t('site_settings.boards.form.name')}
            value={draft.name}
            onChange={(name) => setDraft({ ...draft, name })}
          />
          <TextField
            label={t('site_settings.boards.form.slug')}
            value={draft.slug}
            onChange={(slug) => setDraft({ ...draft, slug })}
            placeholder={draft.name.trim().toLowerCase().replace(/\s+/g, '-')}
            help={t('site_settings.boards.form.slug_help')}
          />
          <div className="space-y-1.5">
            <Label htmlFor="board-description">{t('site_settings.boards.form.description')}</Label>
            <Textarea
              id="board-description"
              rows={3}
              value={draft.description}
              onChange={(event) => setDraft({ ...draft, description: event.target.value })}
            />
          </div>
          <SelectField
            label={t('site_settings.boards.form.visibility')}
            value={draft.visibility}
            onChange={(visibility) => setDraft({ ...draft, visibility })}
            options={VISIBILITIES.map((value) => ({
              value,
              label: t(`site_settings.boards.visibility.${value}`),
            }))}
            help={t('site_settings.boards.form.visibility_help')}
          />
        </>
      )}
      onCreate={(draft) => create.mutateAsync(input(draft))}
      onUpdate={(board, draft) => update.mutateAsync({ id: board.id, ...input(draft) })}
      onDelete={(board) => remove.mutateAsync(board.id)}
      onReorder={(ids) => reorder.mutate(ids)}
      deleteConfirmation={t('common.confirmation_board_delete')}
      error={create.error ?? update.error ?? remove.error ?? reorder.error}
      onDismissError={() =>
        [create, update, remove, reorder].forEach((m) => {
          m.reset()
        })
      }
    />
  )
}
