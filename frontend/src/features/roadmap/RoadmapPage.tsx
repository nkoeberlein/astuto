import { useSuspenseQuery } from '@tanstack/react-query'
import {
  boardsQuery,
  ROADMAP_SORT_OPTIONS,
  type RoadmapSortBy,
  roadmapQuery,
  sessionQuery,
} from '@/api/queries'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useI18n } from '@/lib/i18n'
import { RoadmapColumn } from './RoadmapColumn'
import { RoadmapFilters } from './RoadmapFilters'
import { type RoadmapFilters as Filters, filterRoadmap } from './search'

type Props = {
  filters: Filters
  onFiltersChange: (changes: Partial<Filters>) => void
}

export function RoadmapPage({ filters, onFiltersChange }: Props) {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const { data: roadmap } = useSuspenseQuery(roadmapQuery(filters.sortBy))

  const boardById = new Map(boards.map((board) => [board.id, board]))
  const columns = filterRoadmap(roadmap.columns, filters)
  // The board name only helps when posts of several boards are visible
  const showBoard = boards.length > 1 && filters.boardIds.length !== 1

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold tracking-tight">{t('roadmap.title')}</h1>
        <Select
          value={filters.sortBy}
          onValueChange={(value) => onFiltersChange({ sortBy: value as RoadmapSortBy })}
        >
          <SelectTrigger className="w-48" aria-label={t('board.sort_by_box.title')}>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {ROADMAP_SORT_OPTIONS.map((option) => (
              <SelectItem key={option} value={option}>
                {t(`roadmap.sort_by.${option}`)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <RoadmapFilters
        boards={boards}
        statuses={roadmap.columns.map((column) => column.status)}
        filters={filters}
        onChange={onFiltersChange}
      />

      {columns.length === 0 ? (
        <p className="rounded-lg border border-dashed p-8 text-center text-muted-foreground">
          {t('roadmap.empty')}
        </p>
      ) : (
        // Horizontal scrolling on small screens, side by side from md up
        <div className="-mx-4 flex snap-x snap-mandatory scroll-px-4 items-start gap-4 overflow-x-auto px-4 pb-2 md:snap-none">
          {columns.map((column) => (
            <RoadmapColumn
              key={column.status.id}
              column={column}
              boardById={boardById}
              showBoard={showBoard}
              showVoteCount={session.tenant.settings.showVoteCount}
            />
          ))}
        </div>
      )}
    </div>
  )
}
