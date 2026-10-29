import { useSuspenseQuery } from '@tanstack/react-query'
import { Link, useNavigate } from '@tanstack/react-router'
import { ArrowLeft, Link2, Pencil, ShieldCheck, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useDeletePost, useUpdatePost } from '@/api/mutations'
import {
  boardsQuery,
  commentsQuery,
  postQuery,
  postStatusesQuery,
  sessionQuery,
} from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Markdown } from '@/components/Markdown'
import { UserAvatar } from '@/components/UserAvatar'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Separator } from '@/components/ui/separator'
import { Textarea } from '@/components/ui/textarea'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { isModerator } from '@/lib/roles'
import { AiSummary } from './AiSummary'
import { CommentForm } from './CommentForm'
import { CommentList } from './CommentList'
import { CommentLoginHint } from './CommentLoginHint'
import { FollowButton } from './FollowButton'
import { MergePost } from './MergePost'
import { StatusBadge } from './StatusBadge'
import { VoteButton } from './VoteButton'

const NO_STATUS_VALUE = '__none__'

export function PostPage({ postSlug }: { postSlug: string }) {
  const { t, locale } = useI18n()
  const navigate = useNavigate()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: post } = useSuspenseQuery(postQuery(postSlug))
  const { data: comments } = useSuspenseQuery(commentsQuery(postSlug))
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const { data: boards } = useSuspenseQuery(boardsQuery)

  const updatePost = useUpdatePost(post.slug)
  const deletePost = useDeletePost(post.slug)

  const [editing, setEditing] = useState(false)
  const [titleDraft, setTitleDraft] = useState(post.title)
  const [descriptionDraft, setDescriptionDraft] = useState(post.description ?? '')
  const [sourceUrlDraft, setSourceUrlDraft] = useState(post.source?.url ?? '')
  const [sourceLabelDraft, setSourceLabelDraft] = useState(post.source?.label ?? '')

  const user = session.user
  const canModerate = isModerator(user)
  const canEdit = user !== null && (user.id === post.author?.id || canModerate)

  const board = boards.find((b) => b.id === post.boardId)
  const status = statuses.find((s) => s.id === post.postStatusId)

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px] lg:items-start lg:gap-8 xl:grid-cols-[minmax(0,1fr)_360px]">
      <article className="min-w-0 space-y-6">
        {board && (
          <Link
            to="/boards/$boardSlug"
            params={{ boardSlug: board.slug }}
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="size-4 rtl:-scale-x-100" aria-hidden /> {board.name}
          </Link>
        )}

        <header className="flex gap-4 rounded-xl border bg-card p-5 shadow-2xs">
          {session.tenant.settings.showVoteCount && (
            <VoteButton post={post} signedIn={user !== null} />
          )}
          <div className="min-w-0 flex-1 space-y-3">
            {editing ? (
              <form
                className="space-y-3"
                onSubmit={(event) => {
                  event.preventDefault()
                  updatePost.mutate(
                    {
                      title: titleDraft,
                      description: descriptionDraft || null,
                      ...(canModerate
                        ? {
                            sourceUrl: sourceUrlDraft || null,
                            sourceLabel: sourceLabelDraft || null,
                          }
                        : {}),
                    },
                    { onSuccess: () => setEditing(false) },
                  )
                }}
              >
                <div className="space-y-1">
                  <Label htmlFor="edit-post-title">{t('board.new_post.title')}</Label>
                  <Input
                    id="edit-post-title"
                    value={titleDraft}
                    onChange={(event) => setTitleDraft(event.target.value)}
                    required
                    minLength={4}
                    maxLength={128}
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="edit-post-description">{t('board.new_post.description')}</Label>
                  <Textarea
                    id="edit-post-description"
                    value={descriptionDraft}
                    onChange={(event) => setDescriptionDraft(event.target.value)}
                    rows={5}
                  />
                </div>
                {canModerate && (
                  <div className="grid gap-3 sm:grid-cols-[10rem_1fr]">
                    <div className="space-y-1">
                      <Label htmlFor="edit-post-source-label">{t('post.source.label')}</Label>
                      <Input
                        id="edit-post-source-label"
                        value={sourceLabelDraft}
                        onChange={(event) => setSourceLabelDraft(event.target.value)}
                        maxLength={40}
                        placeholder="Slack"
                      />
                    </div>
                    <div className="space-y-1">
                      <Label htmlFor="edit-post-source-url">{t('post.source.url')}</Label>
                      <Input
                        id="edit-post-source-url"
                        type="url"
                        value={sourceUrlDraft}
                        onChange={(event) => setSourceUrlDraft(event.target.value)}
                        placeholder="https://"
                      />
                    </div>
                  </div>
                )}
                <div className="flex gap-2">
                  <Button type="submit" size="sm" disabled={updatePost.isPending}>
                    {t('common.buttons.update')}
                  </Button>
                  <Button
                    type="button"
                    size="sm"
                    variant="ghost"
                    onClick={() => {
                      setTitleDraft(post.title)
                      setDescriptionDraft(post.description ?? '')
                      updatePost.reset()
                      setEditing(false)
                    }}
                  >
                    {t('common.buttons.cancel')}
                  </Button>
                </div>
                <FormError error={updatePost.error} />
              </form>
            ) : (
              <>
                <h1 className="text-2xl font-bold tracking-tight">{post.title}</h1>
                <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
                  <StatusBadge status={status} />
                  {post.author ? (
                    <span className="flex items-center gap-2">
                      <UserAvatar
                        name={post.author.fullName}
                        url={post.author.avatarUrl}
                        className="size-5"
                      />
                      {t('post.published_by')} {post.author.fullName}
                    </span>
                  ) : (
                    <span>{t('post.published_anonymously')}</span>
                  )}
                  <time dateTime={post.createdAt}>
                    {formatRelativeTime(post.createdAt, locale)}
                  </time>
                  {post.source && <PostSource source={post.source} />}
                </div>
                {post.description && (
                  <div className="pt-2">
                    <Markdown>{post.description}</Markdown>
                  </div>
                )}
                {post.mergedPosts.length > 0 && (
                  <p className="text-sm text-muted-foreground">
                    {t('post.merge.merged_from')}{' '}
                    {post.mergedPosts.map((merged) => merged.title).join(' · ')}
                  </p>
                )}
              </>
            )}
          </div>
        </header>

        <Separator />

        <section
          className="space-y-4 rounded-xl border bg-card p-5 shadow-2xs"
          aria-labelledby="comments-title"
        >
          <h2 id="comments-title" className="text-lg font-semibold">
            {t('post.comments.title')}
          </h2>
          <CommentList
            comments={comments}
            postSlug={user ? post.slug : undefined}
            currentUser={user}
          />
          {user ? (
            <CommentForm postSlug={post.slug} canMarkAsUpdate={canModerate} />
          ) : (
            <CommentLoginHint />
          )}
        </section>
      </article>

      <aside className="space-y-4 lg:sticky lg:top-20">
        <div className="space-y-3 rounded-xl border bg-card p-4 shadow-2xs">
          {user && <FollowButton postSlug={post.slug} followed={post.followed} />}

          {canEdit && !editing && (
            <div className="flex flex-wrap gap-2 pt-1">
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="flex-1 gap-1.5"
                onClick={() => {
                  setTitleDraft(post.title)
                  setDescriptionDraft(post.description ?? '')
                  updatePost.reset()
                  setEditing(true)
                }}
              >
                <Pencil className="size-3.5" aria-hidden />
                {t('common.buttons.edit')}
              </Button>
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="gap-1.5 text-destructive hover:text-destructive"
                disabled={deletePost.isPending}
                onClick={() => {
                  if (!window.confirm(t('common.confirmation'))) return
                  deletePost.mutate(undefined, {
                    onSuccess: () =>
                      board
                        ? navigate({ to: '/boards/$boardSlug', params: { boardSlug: board.slug } })
                        : navigate({ to: '/' }),
                  })
                }}
              >
                <Trash2 className="size-3.5" aria-hidden />
                {t('common.buttons.delete')}
              </Button>
            </div>
          )}
          <FormError error={deletePost.error} />
        </div>

        {canModerate && (
          <section
            aria-label={t('header.menu.moderation')}
            className="space-y-3 rounded-xl border border-primary/20 bg-card p-4 shadow-2xs"
          >
            <div className="flex items-center gap-2 text-sm font-semibold">
              <ShieldCheck className="size-4 text-primary" aria-hidden />
              <span>{t('header.menu.moderation')}</span>
            </div>

            <div className="space-y-1.5">
              <Label className="text-xs text-muted-foreground">
                {t('activerecord.models.post_status.one')}
              </Label>
              <Select
                value={post.postStatusId ? String(post.postStatusId) : NO_STATUS_VALUE}
                onValueChange={(value) =>
                  updatePost.mutate({
                    postStatusId: value === NO_STATUS_VALUE ? null : Number(value),
                  })
                }
              >
                <SelectTrigger aria-label={t('activerecord.models.post_status.one')}>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={NO_STATUS_VALUE}>{t('common.no_status')}</SelectItem>
                  {statuses.map((s) => (
                    <SelectItem key={s.id} value={String(s.id)}>
                      {s.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {boards.length > 1 && (
              <div className="space-y-1.5">
                <Label className="text-xs text-muted-foreground">
                  {t('activerecord.models.board.one')}
                </Label>
                <Select
                  value={String(post.boardId)}
                  onValueChange={(value) => updatePost.mutate({ boardId: Number(value) })}
                >
                  <SelectTrigger aria-label={t('activerecord.models.board.one')}>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {boards.map((b) => (
                      <SelectItem key={b.id} value={String(b.id)}>
                        {b.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}
            {!editing && <FormError error={updatePost.error} />}
            {session.aiEnabled && <AiSummary postSlug={post.slug} />}
            {board && <MergePost post={post} boardSlug={board.slug} />}
          </section>
        )}
      </aside>
    </div>
  )
}

// Where moderators captured the feedback (Slack, email, ticket); only they get this field
function PostSource({ source }: { source: { url: string | null; label: string | null } }) {
  const { t } = useI18n()
  const text = source.label ?? t('post.source.title')
  return (
    <span className="inline-flex items-center gap-1" title={t('post.source.title')}>
      <Link2 className="size-3.5" aria-hidden />
      {source.url ? (
        <a href={source.url} target="_blank" rel="noopener noreferrer" className="underline">
          {text}
        </a>
      ) : (
        text
      )}
    </span>
  )
}
