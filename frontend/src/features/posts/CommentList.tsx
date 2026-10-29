import { Pencil, Trash2 } from 'lucide-react'
import { useState } from 'react'
import type { Comment, Session } from '@/api/client'
import { useDeleteComment, useUpdateComment } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Markdown } from '@/components/Markdown'
import { UserAvatar } from '@/components/UserAvatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { isModerator } from '@/lib/roles'
import { useCommentTranslation } from './AiTranslation'
import { CommentForm } from './CommentForm'

// Top-level comments with their replies (one level deep, like the legacy UI)
export function groupComments(comments: Comment[]) {
  const replies = new Map<number, Comment[]>()
  for (const comment of comments) {
    if (comment.parentId === null) continue
    replies.set(comment.parentId, [...(replies.get(comment.parentId) ?? []), comment])
  }
  return comments
    .filter((comment) => comment.parentId === null)
    .map((comment) => ({ comment, replies: replies.get(comment.id) ?? [] }))
}

// postSlug enables reply/edit/delete (signed-in users only)
// canTranslate: AI translation button (moderators, when the server has AI enabled)
type ReplyProps = {
  postSlug?: string
  currentUser?: Session['user']
  canTranslate?: boolean
}

function CommentItem({
  comment,
  postSlug,
  currentUser,
  canTranslate = false,
}: { comment: Comment } & ReplyProps) {
  const { t, locale } = useI18n()
  const [replying, setReplying] = useState(false)
  const [editing, setEditing] = useState(false)
  const [draftBody, setDraftBody] = useState(comment.body)
  const [draftUpdate, setDraftUpdate] = useState(comment.isPostUpdate)
  const updateComment = useUpdateComment(postSlug ?? '')
  const deleteComment = useDeleteComment(postSlug ?? '')
  const translation = useCommentTranslation(postSlug ?? '', comment.id)

  const name = comment.author?.fullName ?? t('post.published_anonymously')
  const canModerate = isModerator(currentUser)
  const canManage =
    Boolean(postSlug) &&
    currentUser !== null &&
    currentUser !== undefined &&
    (currentUser.id === comment.author?.id || canModerate)

  return (
    <div className="flex gap-3">
      <UserAvatar name={name} url={comment.author?.avatarUrl ?? ''} />
      <div className="min-w-0 flex-1 space-y-1.5">
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <span className="font-medium">{name}</span>
          {comment.isPostUpdate && <Badge>{t('post.comments.post_update_badge')}</Badge>}
          <time className="text-xs text-muted-foreground" dateTime={comment.createdAt}>
            {formatRelativeTime(comment.createdAt, locale)}
          </time>
        </div>

        {editing && postSlug ? (
          <form
            className="space-y-2 rounded-lg border bg-card p-3"
            onSubmit={(event) => {
              event.preventDefault()
              updateComment.mutate(
                {
                  id: comment.id,
                  changes: { body: draftBody, isPostUpdate: draftUpdate },
                },
                { onSuccess: () => setEditing(false) },
              )
            }}
          >
            <Textarea
              value={draftBody}
              onChange={(event) => setDraftBody(event.target.value)}
              rows={3}
              required
              aria-label={t('post.new_comment.body_placeholder')}
            />
            {canModerate && (
              <div className="flex items-center gap-2">
                <Checkbox
                  id={`edit-comment-update-${comment.id}`}
                  checked={draftUpdate}
                  onCheckedChange={(checked) => setDraftUpdate(checked === true)}
                />
                <Label htmlFor={`edit-comment-update-${comment.id}`} className="text-xs">
                  {t('post.comments.post_update_badge')}
                </Label>
              </div>
            )}
            <div className="flex gap-2">
              <Button type="submit" size="sm" disabled={updateComment.isPending}>
                {t('common.buttons.update')}
              </Button>
              <Button
                type="button"
                size="sm"
                variant="ghost"
                onClick={() => {
                  setDraftBody(comment.body)
                  setDraftUpdate(comment.isPostUpdate)
                  updateComment.reset()
                  setEditing(false)
                }}
              >
                {t('common.buttons.cancel')}
              </Button>
            </div>
            <FormError error={updateComment.error} />
          </form>
        ) : (
          <Markdown>{comment.body}</Markdown>
        )}
        {canTranslate && postSlug && !editing && translation.result}

        <div className="flex flex-wrap items-center gap-3 pt-0.5">
          {postSlug && comment.parentId === null && !replying && !editing && (
            <Button
              variant="link"
              size="sm"
              className="h-auto p-0 text-xs"
              onClick={() => setReplying(true)}
            >
              {t('post.comments.reply_button')}
            </Button>
          )}
          {canTranslate && postSlug && !editing && translation.button}
          {canManage && !editing && (
            <>
              <Button
                variant="link"
                size="sm"
                className="h-auto gap-1 p-0 text-xs text-muted-foreground hover:text-foreground"
                onClick={() => {
                  setDraftBody(comment.body)
                  setDraftUpdate(comment.isPostUpdate)
                  updateComment.reset()
                  setEditing(true)
                }}
              >
                <Pencil className="size-3" aria-hidden />
                {t('common.buttons.edit')}
              </Button>
              <Button
                variant="link"
                size="sm"
                className="h-auto gap-1 p-0 text-xs text-destructive"
                disabled={deleteComment.isPending}
                onClick={() => {
                  if (window.confirm(t('common.confirmation'))) deleteComment.mutate(comment.id)
                }}
              >
                <Trash2 className="size-3" aria-hidden />
                {t('common.buttons.delete')}
              </Button>
            </>
          )}
        </div>
        <FormError error={deleteComment.error} />

        {postSlug && replying && (
          <CommentForm
            postSlug={postSlug}
            parentId={comment.id}
            onDone={() => setReplying(false)}
          />
        )}
      </div>
    </div>
  )
}

export function CommentList({
  comments,
  postSlug,
  currentUser,
  canTranslate,
}: { comments: Comment[] } & ReplyProps) {
  const { t } = useI18n()
  if (comments.length === 0) {
    return <p className="text-sm text-muted-foreground">{t('post.comments.empty')}</p>
  }
  return (
    <ul className="space-y-6">
      {groupComments(comments).map(({ comment, replies }) => (
        <li key={comment.id} className="space-y-4">
          <CommentItem
            comment={comment}
            postSlug={postSlug}
            currentUser={currentUser}
            canTranslate={canTranslate}
          />
          {replies.length > 0 && (
            <ul className="ms-10 space-y-4 border-s ps-4">
              {replies.map((reply) => (
                <li key={reply.id}>
                  <CommentItem
                    comment={reply}
                    postSlug={postSlug}
                    currentUser={currentUser}
                    canTranslate={canTranslate}
                  />
                </li>
              ))}
            </ul>
          )}
        </li>
      ))}
    </ul>
  )
}
