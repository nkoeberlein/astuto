import { useSuspenseInfiniteQuery, useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { Pencil, Plus, Rss, Trash2 } from 'lucide-react'
import { useState } from 'react'
import type { ChangelogEntry } from '@/api/client'
import { useDeleteChangelogEntry } from '@/api/mutations'
import { changelogQuery, sessionQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Markdown } from '@/components/Markdown'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'
import { isModerator } from '@/lib/roles'
import { ChangelogEntryForm } from './ChangelogEntryForm'

// Release notes; moderators write, publish and edit entries here
export function ChangelogPage() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const entries = useSuspenseInfiniteQuery(changelogQuery)
  const [creating, setCreating] = useState(false)
  const canEdit = isModerator(session.user)
  const items = entries.data.pages.flatMap((page) => page.entries)

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold tracking-tight">{t('changelog.title')}</h1>
        <div className="flex items-center gap-3">
          {!session.tenant.settings.isPrivate && (
            <a
              href="/changelog/feed"
              className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
            >
              <Rss className="size-3" aria-hidden />
              {t('changelog.rss_feed')}
            </a>
          )}
          {canEdit && !creating && (
            <Button type="button" size="sm" className="gap-1.5" onClick={() => setCreating(true)}>
              <Plus className="size-4" aria-hidden />
              {t('changelog.new_entry')}
            </Button>
          )}
        </div>
      </div>

      {creating && <ChangelogEntryForm onDone={() => setCreating(false)} />}

      {items.length === 0 && !creating ? (
        <p className="rounded-xl border border-dashed p-10 text-center text-muted-foreground">
          {t('changelog.empty')}
        </p>
      ) : (
        <ol className="space-y-5">
          {items.map((entry) => (
            <li key={entry.id}>
              <EntryCard entry={entry} canEdit={canEdit} />
            </li>
          ))}
        </ol>
      )}

      {entries.hasNextPage && (
        <div className="flex justify-center">
          <Button
            variant="outline"
            onClick={() => entries.fetchNextPage()}
            disabled={entries.isFetchingNextPage}
          >
            {t('board.posts_list.load_more')}
          </Button>
        </div>
      )}
    </div>
  )
}

function EntryCard({ entry, canEdit }: { entry: ChangelogEntry; canEdit: boolean }) {
  const { t, locale } = useI18n()
  const [editing, setEditing] = useState(false)
  const remove = useDeleteChangelogEntry()

  if (editing) return <ChangelogEntryForm entry={entry} onDone={() => setEditing(false)} />

  return (
    <article
      id={`entry-${entry.id}`}
      className="scroll-mt-24 space-y-3 rounded-xl border bg-card p-5 shadow-2xs"
      aria-labelledby={`entry-${entry.id}-title`}
    >
      <header className="space-y-1">
        <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
          {entry.publishedAt ? (
            <time dateTime={entry.publishedAt}>
              {new Date(entry.publishedAt).toLocaleDateString(locale, { dateStyle: 'long' })}
            </time>
          ) : (
            <Badge variant="outline">{t('changelog.draft')}</Badge>
          )}
        </div>
        <h2 id={`entry-${entry.id}-title`} className="text-lg font-semibold">
          {entry.title}
        </h2>
      </header>
      {entry.body && <Markdown>{entry.body}</Markdown>}
      {entry.posts.length > 0 && (
        <div className="space-y-1 text-sm">
          <p className="font-medium">{t('changelog.delivers')}</p>
          <ul className="flex flex-wrap gap-x-4 gap-y-1">
            {entry.posts.map((post) => (
              <li key={post.id}>
                <Link
                  to="/posts/$postSlug"
                  params={{ postSlug: post.slug }}
                  className="text-primary hover:underline"
                >
                  {post.title}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      )}
      {canEdit && (
        <div className="flex gap-3 pt-1">
          <Button
            variant="link"
            size="sm"
            className="h-auto gap-1 p-0 text-xs text-muted-foreground hover:text-foreground"
            onClick={() => setEditing(true)}
          >
            <Pencil className="size-3" aria-hidden />
            {t('common.buttons.edit')}
          </Button>
          <Button
            variant="link"
            size="sm"
            className="h-auto gap-1 p-0 text-xs text-destructive"
            disabled={remove.isPending}
            onClick={() => {
              if (window.confirm(t('common.confirmation'))) remove.mutate(entry.id)
            }}
          >
            <Trash2 className="size-3" aria-hidden />
            {t('common.buttons.delete')}
          </Button>
        </div>
      )}
      <FormError error={remove.error} />
    </article>
  )
}
