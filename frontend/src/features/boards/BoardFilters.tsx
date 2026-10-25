import { useEffect, useState } from 'react'
import type { PostStatus } from '@/api/client'
import { type PostFilters, SORT_OPTIONS, type SortBy } from '@/api/queries'
import { FilterChip } from '@/components/FilterChip'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useI18n } from '@/lib/i18n'
import { toggleId } from '@/lib/search-params'

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
          {statuses.map((status) => (
            <FilterChip
              key={status.id}
              active={filters.statusIds.includes(status.id)}
              onClick={() => onChange({ statusIds: toggleId(filters.statusIds, status.id) })}
              color={status.color}
            >
              {status.name}
            </FilterChip>
          ))}
        </fieldset>
      )}
    </div>
  )
}
