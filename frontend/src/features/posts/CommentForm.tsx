import { type FormEvent, useId, useState } from 'react'
import { useCreateComment } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'

type Props = {
  postSlug: string
  parentId?: number
  // Moderators can mark a comment as an official update for followers
  canMarkAsUpdate?: boolean
  onDone?: () => void
}

export function CommentForm({ postSlug, parentId, canMarkAsUpdate = false, onDone }: Props) {
  const { t } = useI18n()
  const id = useId()
  const [body, setBody] = useState('')
  const [isPostUpdate, setIsPostUpdate] = useState(false)
  const create = useCreateComment(postSlug)

  const submit = (event: FormEvent) => {
    event.preventDefault()
    if (!body.trim()) return
    create.mutate(
      { body, parentId: parentId ?? null, isPostUpdate },
      {
        onSuccess: () => {
          setBody('')
          setIsPostUpdate(false)
          onDone?.()
        },
      },
    )
  }

  return (
    <form onSubmit={submit} className="space-y-2">
      <Textarea
        value={body}
        onChange={(event) => setBody(event.target.value)}
        placeholder={t('post.new_comment.body_placeholder')}
        aria-label={t('post.new_comment.body_placeholder')}
        rows={parentId ? 2 : 3}
        autoFocus={parentId !== undefined}
      />
      <FormError error={create.error} />
      <div className="flex flex-wrap items-center gap-4">
        <Button type="submit" size="sm" disabled={create.isPending || !body.trim()}>
          {t('post.new_comment.submit_button')}
        </Button>
        {canMarkAsUpdate && !parentId && (
          <div className="flex items-center gap-2 text-sm">
            <Checkbox
              id={id}
              checked={isPostUpdate}
              onCheckedChange={(checked) => setIsPostUpdate(checked === true)}
            />
            <Label htmlFor={id}>{t('post.new_comment.is_post_update')}</Label>
            {isPostUpdate && (
              <span className="text-muted-foreground">
                {t('post.new_comment.user_notification')}
              </span>
            )}
          </div>
        )}
        {onDone && (
          <Button type="button" size="sm" variant="ghost" onClick={onDone}>
            {t('board.new_post.cancel_button')}
          </Button>
        )}
      </div>
    </form>
  )
}
