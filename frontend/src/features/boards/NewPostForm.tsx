import { useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { Link, useNavigate } from '@tanstack/react-router'
import { type FormEvent, useId, useState } from 'react'
import type { Board, Session } from '@/api/client'
import { useCreatePost } from '@/api/mutations'
import { postStatusesQuery, similarPostsQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { useLoginRedirect } from '@/features/auth/redirect'
import { useI18n } from '@/lib/i18n'
import { isModerator } from '@/lib/roles'

type Props = { board: Board; session: Session }

export function NewPostForm({ board, session }: Props) {
  const { t } = useI18n()
  const loginRedirect = useLoginRedirect()
  const [open, setOpen] = useState(false)
  const [submittedPending, setSubmittedPending] = useState(false)
  const canPost = session.user !== null || session.tenant.settings.allowAnonymousFeedback

  if (!canPost) {
    return (
      <Button asChild>
        <Link to="/login" search={{ redirect: loginRedirect }}>
          {t('board.new_post.login_button')}
        </Link>
      </Button>
    )
  }

  if (!open) {
    return (
      <div className="space-y-2">
        <Button onClick={() => setOpen(true)}>{t('board.new_post.submit_button')}</Button>
        {submittedPending && (
          <p role="status" className="text-sm text-muted-foreground">
            {t('board.new_post.submit_pending')}
          </p>
        )}
      </div>
    )
  }

  return (
    <PostForm
      board={board}
      session={session}
      onClose={(pending) => {
        setSubmittedPending(pending)
        setOpen(false)
      }}
    />
  )
}

function PostForm(props: Props & { onClose: (pending: boolean) => void }) {
  const { board, session, onClose } = props
  const { t } = useI18n()
  const loginRedirect = useLoginRedirect()
  const navigate = useNavigate()
  const ids = { title: useId(), description: useId() }
  const create = useCreatePost(board.slug)
  // Anti-spam: the server rejects forms sent within two seconds or with the honeypot filled.
  // A duration (not a timestamp) keeps a wrong client clock from mattering.
  const [renderedAt] = useState(() => performance.now())
  const [honeypot, setHoneypot] = useState('')
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [titleMissing, setTitleMissing] = useState(false)
  const similarPosts = useQuery(similarPostsQuery(board.slug, title))
  const duplicateSuggestions = (similarPosts.data?.posts ?? []).slice(0, 5)

  const { user } = session
  const allowAnonymous = session.tenant.settings.allowAnonymousFeedback

  // Moderators can directly assign an initial status to the new post (#119)
  const canModerate = isModerator(user)
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const [statusId, setStatusId] = useState('')

  const submit = (isAnonymous: boolean) => {
    if (!title.trim()) return setTitleMissing(true)
    create.mutate(
      {
        title,
        description,
        isAnonymous,
        postStatusId: canModerate && statusId ? Number(statusId) : undefined,
        honeypot,
        formFillMs: Math.round(performance.now() - renderedAt),
      },
      {
        onSuccess: (post) => {
          if (post.approvalStatus === 'approved') {
            void navigate({ to: '/posts/$postSlug', params: { postSlug: post.slug } })
          } else {
            onClose(true)
          }
        },
      },
    )
  }

  const onSubmit = (event: FormEvent) => {
    event.preventDefault()
    submit(user === null)
  }

  return (
    <Card>
      <CardContent>
        <form onSubmit={onSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor={ids.title}>{t('board.new_post.title')}</Label>
            <Input
              id={ids.title}
              value={title}
              maxLength={128}
              aria-invalid={titleMissing}
              onChange={(event) => {
                setTitle(event.target.value)
                setTitleMissing(false)
              }}
              autoFocus
            />
            {titleMissing && (
              <p className="text-sm text-destructive">{t('board.new_post.no_title')}</p>
            )}
            {duplicateSuggestions.length > 0 && (
              <section
                aria-label={t('board.new_post.similar_posts_title')}
                className="rounded-md border bg-muted/40 p-3 text-sm space-y-1.5"
              >
                <p className="font-medium text-muted-foreground">
                  {t('board.new_post.similar_posts_title')}
                </p>
                <ul className="space-y-1">
                  {duplicateSuggestions.map((item) => (
                    <li key={item.id} className="flex items-center justify-between gap-2">
                      <Link
                        to="/posts/$postSlug"
                        params={{ postSlug: item.slug }}
                        className="truncate text-primary hover:underline"
                      >
                        {item.title}
                      </Link>
                      <span className="shrink-0 text-xs text-muted-foreground">
                        ▲ {item.likesCount}
                      </span>
                    </li>
                  ))}
                </ul>
              </section>
            )}
          </div>
          <div className="space-y-1.5">
            <Label htmlFor={ids.description}>{t('board.new_post.description')}</Label>
            <Textarea
              id={ids.description}
              value={description}
              rows={5}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>

          {canModerate && statuses.length > 0 && (
            <div className="space-y-1.5">
              <Label>{t('board.new_post.status')}</Label>
              <Select value={statusId} onValueChange={setStatusId}>
                <SelectTrigger className="w-48">
                  <SelectValue placeholder={t('common.select_placeholder')} />
                </SelectTrigger>
                <SelectContent>
                  {statuses.map((status) => (
                    <SelectItem key={status.id} value={String(status.id)}>
                      <span className="flex items-center gap-2">
                        <span
                          className="size-2.5 rounded-full"
                          style={{ backgroundColor: status.color }}
                        />
                        {status.name}
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Honeypot: hidden from people, bots tend to fill it */}
          <input
            type="text"
            name="website"
            value={honeypot}
            onChange={(event) => setHoneypot(event.target.value)}
            tabIndex={-1}
            autoComplete="off"
            aria-hidden
            // Out of sight without a sideways offset (which would scroll the page in RTL)
            className="pointer-events-none absolute size-px overflow-hidden opacity-0 [clip-path:inset(50%)]"
          />

          <p className="text-sm text-muted-foreground">
            {user
              ? t('board.new_post.non_anonymous_submission_help', { name: user.fullName })
              : t('board.new_post.anonymous_submission_help')}
          </p>
          <FormError error={create.error} />

          <div className="flex flex-wrap gap-2">
            {user && (
              <Button type="submit" disabled={create.isPending}>
                {t('board.new_post.submit_button')}
              </Button>
            )}
            {allowAnonymous && (
              <Button
                type={user ? 'button' : 'submit'}
                variant={user ? 'outline' : 'default'}
                disabled={create.isPending}
                onClick={user ? () => submit(true) : undefined}
              >
                {t('board.new_post.submit_anonymous_button')}
              </Button>
            )}
            {!user && (
              <Button asChild variant="outline">
                <Link to="/login" search={{ redirect: loginRedirect }}>
                  {t('board.new_post.login_button')}
                </Link>
              </Button>
            )}
            <Button type="button" variant="ghost" onClick={() => onClose(false)}>
              {t('board.new_post.cancel_button')}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
