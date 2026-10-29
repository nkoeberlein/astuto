import { useInfiniteQuery } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { Merge } from 'lucide-react'
import { useState } from 'react'
import type { Post } from '@/api/client'
import { useMergePost } from '@/api/mutations'
import { boardPostsQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useI18n } from '@/lib/i18n'

// Moderators: merge this post into another one of the same board (search by title)
export function MergePost({ post, boardSlug }: { post: Post; boardSlug: string }) {
  const { t } = useI18n()
  const navigate = useNavigate()
  const merge = useMergePost(post.slug)
  const [open, setOpen] = useState(false)
  const [search, setSearch] = useState('')
  const query = search.trim()
  const results = useInfiniteQuery({
    ...boardPostsQuery(boardSlug, { search: query, sortBy: 'most_voted', statusIds: [] }),
    enabled: open && query.length >= 2,
  })
  const candidates = (results.data?.pages.flatMap((page) => page.posts) ?? [])
    .filter((candidate) => candidate.id !== post.id)
    .slice(0, 6)

  if (!open) {
    return (
      <Button
        type="button"
        variant="outline"
        size="sm"
        className="w-full gap-1.5"
        onClick={() => setOpen(true)}
      >
        <Merge className="size-4" aria-hidden />
        {t('post.merge.button')}
      </Button>
    )
  }

  return (
    <div className="space-y-2 rounded-lg border p-3">
      <label htmlFor="merge-search" className="block text-sm font-medium">
        {t('post.merge.search')}
      </label>
      <Input id="merge-search" value={search} onChange={(event) => setSearch(event.target.value)} />
      <p className="text-xs text-muted-foreground">{t('post.merge.help')}</p>
      <ul className="space-y-1">
        {candidates.map((candidate) => (
          <li key={candidate.id} className="flex items-center justify-between gap-2 text-sm">
            <span className="min-w-0 truncate">{candidate.title}</span>
            <Button
              type="button"
              size="sm"
              variant="secondary"
              disabled={merge.isPending}
              onClick={() => {
                if (!window.confirm(t('post.merge.confirmation', { target: candidate.title })))
                  return
                merge.mutate(candidate.id, {
                  onSuccess: (target) =>
                    navigate({
                      to: '/posts/$postSlug',
                      params: { postSlug: target.slug },
                      replace: true,
                    }),
                })
              }}
            >
              {t('post.merge.into_this')}
            </Button>
          </li>
        ))}
      </ul>
      <FormError error={merge.error} />
      <Button type="button" variant="ghost" size="sm" onClick={() => setOpen(false)}>
        {t('common.buttons.cancel')}
      </Button>
    </div>
  )
}
