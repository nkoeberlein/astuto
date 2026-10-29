import { ArrowDown, ArrowUp, Pencil, Plus, Trash2 } from 'lucide-react'
import { type FormEvent, type ReactNode, useState } from 'react'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'
import { moveId } from './list'

type Props<T extends { id: number }, Draft> = {
  title: string
  items: T[]
  emptyText: string
  // How a row looks, and the draft a new or edited item starts from
  renderItem: (item: T) => ReactNode
  itemName: (item: T) => string
  newDraft: () => Draft
  draftFor: (item: T) => Draft
  renderForm: (draft: Draft, setDraft: (draft: Draft) => void) => ReactNode
  onCreate: (draft: Draft) => Promise<unknown>
  onUpdate: (item: T, draft: Draft) => Promise<unknown>
  onDelete: (item: T) => Promise<unknown>
  onReorder: (ids: number[]) => void
  deleteConfirmation: string
  error: Error | null
  onDismissError: () => void
}

// Editable, ordered list for site settings (boards, statuses): edit inline, move up and down,
// delete after a confirmation, add new items below
export function ListEditor<T extends { id: number }, Draft>(props: Props<T, Draft>) {
  const { t } = useI18n()
  const [editingId, setOpenForm] = useState<number | 'new' | null>(null)
  // Opening or closing a form clears the last error
  const setEditingId = (id: number | 'new' | null) => {
    props.onDismissError()
    setOpenForm(id)
  }
  const ids = props.items.map((item) => item.id)

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold tracking-tight">{props.title}</h2>
      <FormError error={props.error} />

      {props.items.length === 0 ? (
        <p className="rounded-lg border border-dashed p-6 text-center text-muted-foreground">
          {props.emptyText}
        </p>
      ) : (
        <ol className="divide-y rounded-xl border bg-card shadow-2xs">
          {props.items.map((item, index) =>
            editingId === item.id ? (
              <li key={item.id} className="p-4">
                <ItemForm
                  initial={props.draftFor(item)}
                  renderForm={props.renderForm}
                  submitLabel={t('common.buttons.update')}
                  onSubmit={(draft) => props.onUpdate(item, draft).then(() => setEditingId(null))}
                  onCancel={() => setEditingId(null)}
                />
              </li>
            ) : (
              <li key={item.id} className="flex items-center gap-3 p-3">
                <div className="flex flex-col">
                  <IconButton
                    label={`${props.itemName(item)}: ${t('common.buttons.move_up')}`}
                    disabled={index === 0}
                    onClick={() => props.onReorder(moveId(ids, index, -1))}
                  >
                    <ArrowUp className="size-4" aria-hidden />
                  </IconButton>
                  <IconButton
                    label={`${props.itemName(item)}: ${t('common.buttons.move_down')}`}
                    disabled={index === ids.length - 1}
                    onClick={() => props.onReorder(moveId(ids, index, 1))}
                  >
                    <ArrowDown className="size-4" aria-hidden />
                  </IconButton>
                </div>
                <div className="min-w-0 flex-1">{props.renderItem(item)}</div>
                <div className="flex shrink-0 gap-1">
                  <IconButton
                    label={`${props.itemName(item)}: ${t('common.buttons.edit')}`}
                    onClick={() => setEditingId(item.id)}
                  >
                    <Pencil className="size-4" aria-hidden />
                  </IconButton>
                  <IconButton
                    label={`${props.itemName(item)}: ${t('common.buttons.delete')}`}
                    className="text-destructive hover:text-destructive"
                    onClick={() => {
                      if (window.confirm(props.deleteConfirmation)) void props.onDelete(item)
                    }}
                  >
                    <Trash2 className="size-4" aria-hidden />
                  </IconButton>
                </div>
              </li>
            ),
          )}
        </ol>
      )}

      {editingId === 'new' ? (
        <div className="rounded-xl border bg-card p-4 shadow-2xs">
          <ItemForm
            initial={props.newDraft()}
            renderForm={props.renderForm}
            submitLabel={t('common.buttons.create')}
            onSubmit={(draft) => props.onCreate(draft).then(() => setEditingId(null))}
            onCancel={() => setEditingId(null)}
          />
        </div>
      ) : (
        <Button type="button" variant="outline" onClick={() => setEditingId('new')}>
          <Plus className="size-4" aria-hidden />
          {t('common.buttons.new')}
        </Button>
      )}
    </div>
  )
}

function ItemForm<Draft>(props: {
  initial: Draft
  renderForm: (draft: Draft, setDraft: (draft: Draft) => void) => ReactNode
  submitLabel: string
  onSubmit: (draft: Draft) => Promise<unknown>
  onCancel: () => void
}) {
  const { t } = useI18n()
  const [draft, setDraft] = useState(props.initial)
  const [busy, setBusy] = useState(false)

  const submit = (event: FormEvent) => {
    event.preventDefault()
    setBusy(true)
    // Errors show above the list; the form stays open to fix them
    props
      .onSubmit(draft)
      .catch(() => undefined)
      .finally(() => setBusy(false))
  }

  return (
    <form className="space-y-4" onSubmit={submit}>
      {props.renderForm(draft, setDraft)}
      <div className="flex gap-2">
        <Button type="submit" disabled={busy}>
          {props.submitLabel}
        </Button>
        <Button type="button" variant="ghost" onClick={props.onCancel}>
          {t('common.buttons.cancel')}
        </Button>
      </div>
    </form>
  )
}

function IconButton(props: {
  label: string
  onClick: () => void
  disabled?: boolean
  className?: string
  children: ReactNode
}) {
  return (
    <Button
      type="button"
      size="icon"
      variant="ghost"
      aria-label={props.label}
      title={props.label}
      disabled={props.disabled}
      onClick={props.onClick}
      className={`size-7 text-muted-foreground ${props.className ?? ''}`}
    >
      {props.children}
    </Button>
  )
}
