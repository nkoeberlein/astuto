import { useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { Sparkles, X } from 'lucide-react'
import { useState } from 'react'
import type { ChangelogEntry } from '@/api/client'
import { useDraftChangelog, useSaveChangelogEntry } from '@/api/mutations'
import { linkablePostsQuery, sessionQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'

type LinkedPost = { id: number; title: string }

// New or existing changelog entry: title, Markdown text and the posts it delivers
export function ChangelogEntryForm({
  entry,
  onDone,
}: {
  entry?: ChangelogEntry
  onDone: () => void
}) {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const save = useSaveChangelogEntry()
  const draft = useDraftChangelog()
  const [title, setTitle] = useState(entry?.title ?? '')
  const [body, setBody] = useState(entry?.body ?? '')
  const [posts, setPosts] = useState<LinkedPost[]>(entry?.posts ?? [])
  const [search, setSearch] = useState('')
  const candidates = useQuery(linkablePostsQuery(search.trim()))
  const isDraft = !entry?.publishedAt
  const formId = entry ? `changelog-${entry.id}` : 'changelog-new'

  const submit = (published: boolean) =>
    save.mutate(
      { id: entry?.id, changes: { title, body, postIds: posts.map((post) => post.id), published } },
      { onSuccess: onDone },
    )

  return (
    <form
      className="space-y-4 rounded-xl border bg-card p-5 shadow-2xs"
      onSubmit={(event) => {
        event.preventDefault()
        submit(!isDraft)
      }}
    >
      <div className="space-y-1.5">
        <Label htmlFor={`${formId}-title`}>{t('changelog.form.title')}</Label>
        <Input
          id={`${formId}-title`}
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          maxLength={200}
          required
        />
      </div>

      <fieldset className="space-y-2">
        <legend className="text-sm font-medium">{t('changelog.form.posts')}</legend>
        <p className="text-xs text-muted-foreground">{t('changelog.form.posts_help')}</p>
        {posts.length > 0 && (
          <ul className="flex flex-wrap gap-2">
            {posts.map((post) => (
              <li
                key={post.id}
                className="flex items-center gap-1 rounded-full bg-muted py-0.5 ps-3 pe-1 text-sm"
              >
                {post.title}
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  className="size-6 p-0"
                  aria-label={`${t('changelog.form.remove_post')}: ${post.title}`}
                  onClick={() => setPosts(posts.filter((linked) => linked.id !== post.id))}
                >
                  <X className="size-3" aria-hidden />
                </Button>
              </li>
            ))}
          </ul>
        )}
        <Input
          aria-label={t('changelog.form.search_posts')}
          placeholder={t('changelog.form.search_posts')}
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <ul className="space-y-1">
          {(candidates.data ?? [])
            .filter((candidate) => !posts.some((post) => post.id === candidate.id))
            .slice(0, 6)
            .map((candidate) => (
              <li key={candidate.id} className="flex items-center justify-between gap-2 text-sm">
                <span className="min-w-0 truncate">{candidate.title}</span>
                <Button
                  type="button"
                  size="sm"
                  variant="secondary"
                  onClick={() => setPosts([...posts, { id: candidate.id, title: candidate.title }])}
                >
                  {t('changelog.form.add_post')}
                </Button>
              </li>
            ))}
        </ul>
      </fieldset>

      <div className="space-y-1.5">
        <Label htmlFor={`${formId}-body`}>{t('changelog.form.body')}</Label>
        <Textarea
          id={`${formId}-body`}
          value={body}
          onChange={(event) => setBody(event.target.value)}
          rows={8}
        />
        {session.aiEnabled && (
          <div className="space-y-1">
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="gap-1.5"
              disabled={posts.length === 0 || draft.isPending}
              onClick={() =>
                draft.mutate(
                  posts.map((post) => post.id),
                  { onSuccess: (result) => setBody(result.body) },
                )
              }
            >
              <Sparkles className="size-3.5" aria-hidden />
              {draft.isPending
                ? t('changelog.form.ai_draft_loading')
                : t('changelog.form.ai_draft')}
            </Button>
            <p className="text-xs text-muted-foreground">{t('changelog.form.ai_draft_hint')}</p>
            <FormError error={draft.error} />
          </div>
        )}
      </div>

      <FormError error={save.error} />
      <div className="flex flex-wrap gap-2">
        {isDraft ? (
          <>
            <Button type="button" disabled={save.isPending} onClick={() => submit(true)}>
              {t('changelog.form.publish')}
            </Button>
            <Button type="submit" variant="outline" disabled={save.isPending}>
              {t('changelog.form.save_draft')}
            </Button>
          </>
        ) : (
          <>
            <Button type="submit" disabled={save.isPending}>
              {t('common.buttons.update')}
            </Button>
            <Button
              type="button"
              variant="outline"
              disabled={save.isPending}
              onClick={() => submit(false)}
            >
              {t('changelog.form.unpublish')}
            </Button>
          </>
        )}
        <Button type="button" variant="ghost" onClick={onDone}>
          {t('common.buttons.cancel')}
        </Button>
      </div>
    </form>
  )
}
