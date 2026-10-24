import { useEffect, useState } from 'react'
import type { PostStatus } from '@/api/client'
import { type PostFilters, SORT_OPTIONS, type SortBy } from '@/api/queries'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'

type Props = {
  filters: PostFilters
  statuses: PostStatus[]
  onChange: (changes: Partial<PostFilters>) => void
}

export function BoardFilters({ filters, statuses, onChange }: Props) {
  const { t } = useI18n()
  const [search, setSearch] = useState(filters.search)

  // Debounce typing before updating the URL
  useEffect(() => {
    if (search === filters.search) return
    const timeout = setTimeout(() => onChange({ search }), 300)
    return () => clearTimeout(timeout)
  }, [search, filters.search, onChange])

  const toggleStatus = (id: number) => {
    const statusIds = filters.statusIds.includes(id)
      ? filters.statusIds.filter((s) => s !== id)
      : [...filters.statusIds, id]
    onChange({ statusIds })
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-col gap-2 sm:flex-row">
        <Input
          type="search"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={t('board.search_box.title')}
          aria-label={t('board.search_box.title')}
        />
        <Select
          value={filters.sortBy}
          onValueChange={(value) => onChange({ sortBy: value as SortBy })}
        >
          <SelectTrigger className="sm:w-48" aria-label={t('board.sort_by_box.title')}>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {SORT_OPTIONS.map((option) => (
              <SelectItem key={option} value={option}>
                {t(`board.sort_by_box.${option}`)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {statuses.length > 0 && (
        <fieldset className="flex flex-wrap gap-2">
          <legend className="sr-only">{t('board.filter_box.title')}</legend>
          {statuses.map((status) => {
            const active = filters.statusIds.includes(status.id)
            return (
              <button
                key={status.id}
                type="button"
                aria-pressed={active}
                onClick={() => toggleStatus(status.id)}
                className={cn(
                  'flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs',
                  active ? 'border-primary bg-primary/10' : 'text-muted-foreground hover:bg-accent',
                )}
              >
                <span className="size-2 rounded-full" style={{ backgroundColor: status.color }} />
                {status.name}
              </button>
            )
          })}
        </fieldset>
      )}
    </div>
  )
}
