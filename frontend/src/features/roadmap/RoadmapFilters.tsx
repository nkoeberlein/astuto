import type { Board, PostStatus } from '@/api/client'
import { FilterChip } from '@/components/FilterChip'
import { useI18n } from '@/lib/i18n'
import { toggleId } from '@/lib/search-params'
import type { RoadmapFilters as Filters } from './search'

type Props = {
  boards: Board[]
  statuses: PostStatus[]
  filters: Filters
  onChange: (changes: Partial<Filters>) => void
}

// Board and status chips; nothing selected means everything is shown
export function RoadmapFilters({ boards, statuses, filters, onChange }: Props) {
  const { t } = useI18n()

  return (
    <div className="space-y-2">
      {boards.length > 1 && (
        <fieldset className="flex flex-wrap gap-2">
          <legend className="sr-only">{t('roadmap.filter_by_board')}</legend>
          {boards.map((board) => (
            <FilterChip
              key={board.id}
              active={filters.boardIds.includes(board.id)}
              onClick={() => onChange({ boardIds: toggleId(filters.boardIds, board.id) })}
            >
              {board.name}
            </FilterChip>
          ))}
        </fieldset>
      )}
      {statuses.length > 1 && (
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
