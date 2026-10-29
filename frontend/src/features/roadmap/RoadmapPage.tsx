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
import {
  type RoadmapFilters as Filters,
  filterRoadmap,
  type RoadmapScope,
  scopeRoadmap,
} from './search'

type Props = {
  filters: Filters
  onFiltersChange: (changes: Partial<Filters>) => void
  // Embedded in another site (iframe): no heading or sorting, limited to the scope,
  // posts open in a new tab
  embed?: RoadmapScope
}

const NO_SCOPE: RoadmapScope = {
  boardIds: [],
  statusIds: [],
  showBoardFilter: true,
  showStatusFilter: true,
}

export function RoadmapPage({ filters, onFiltersChange, embed }: Props) {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: allBoards } = useSuspenseQuery(boardsQuery)
  const { data: roadmap } = useSuspenseQuery(roadmapQuery(filters.sortBy))

  const scope = embed ?? NO_SCOPE
  const boards = scope.boardIds.length
    ? allBoards.filter((board) => scope.boardIds.includes(board.id))
    : allBoards
  const scopedColumns = scopeRoadmap(roadmap.columns, scope)
  const boardById = new Map(boards.map((board) => [board.id, board]))
  const columns = filterRoadmap(scopedColumns, filters)
  // The board name only helps when posts of several boards are visible
  const showBoard = boards.length > 1 && filters.boardIds.length !== 1

  return (
    <div className={embed ? 'space-y-4' : 'space-y-6'}>
      {!embed && (
        <RoadmapHeading
          sortBy={filters.sortBy}
          onSortChange={(sortBy) => onFiltersChange({ sortBy })}
        />
      )}

      <RoadmapFilters
        boards={scope.showBoardFilter ? boards : []}
        statuses={scope.showStatusFilter ? scopedColumns.map((column) => column.status) : []}
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
              openPostsInNewTab={embed !== undefined}
            />
          ))}
        </div>
      )}
    </div>
  )
}

function RoadmapHeading(props: {
  sortBy: RoadmapSortBy
  onSortChange: (sortBy: RoadmapSortBy) => void
}) {
  const { t } = useI18n()

  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <h1 className="text-2xl font-semibold tracking-tight">{t('roadmap.title')}</h1>
      <Select
        value={props.sortBy}
        onValueChange={(value) => props.onSortChange(value as RoadmapSortBy)}
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
  )
}
