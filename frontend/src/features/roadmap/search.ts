import type { RoadmapColumn } from '@/api/client'
import { ROADMAP_SORT_OPTIONS, type RoadmapSortBy } from '@/api/queries'
import { asText, formatIds, parseIds } from '@/lib/search-params'

// URL search params of the roadmap page, e.g. ?board=1,2&status=3&sort=recently_updated
export type RoadmapSearch = { board?: string; status?: string; sort?: RoadmapSortBy }

// Empty id lists mean "no filter": all boards, all statuses
export type RoadmapFilters = { boardIds: number[]; statusIds: number[]; sortBy: RoadmapSortBy }

export const DEFAULT_ROADMAP_SORT: RoadmapSortBy = 'most_voted'

export function validateRoadmapSearch(search: Record<string, unknown>): RoadmapSearch {
  const sort = ROADMAP_SORT_OPTIONS.find((option) => option === search.sort)
  return { board: asText(search.board), status: asText(search.status), sort }
}

export function filtersFromRoadmapSearch(search: RoadmapSearch): RoadmapFilters {
  return {
    boardIds: parseIds(search.board),
    statusIds: parseIds(search.status),
    sortBy: search.sort ?? DEFAULT_ROADMAP_SORT,
  }
}

export function roadmapSearchFromFilters(filters: RoadmapFilters): RoadmapSearch {
  return {
    board: formatIds(filters.boardIds),
    status: formatIds(filters.statusIds),
    sort: filters.sortBy === DEFAULT_ROADMAP_SORT ? undefined : filters.sortBy,
  }
}

// Columns to show: the status filter hides columns, the board filter hides posts.
// `hiddenCount` is how many posts the server left out of a column (only known without board filter).
export function filterRoadmap(
  columns: RoadmapColumn[],
  filters: RoadmapFilters,
): (RoadmapColumn & { hiddenCount: number })[] {
  return columns
    .filter((column) => !filters.statusIds.length || filters.statusIds.includes(column.status.id))
    .map((column) => {
      if (!filters.boardIds.length) {
        return { ...column, hiddenCount: column.postsCount - column.posts.length }
      }
      const posts = column.posts.filter((post) => filters.boardIds.includes(post.boardId))
      return { ...column, posts, postsCount: posts.length, hiddenCount: 0 }
    })
}

// Extra URL params of the embedded roadmap, the same as in the legacy UI so existing embeds keep
// working: ?show_boards=1,2&show_statuses=3&show_board_filter=false&show_status_filter=false
export type EmbeddedRoadmapSearch = RoadmapSearch & {
  show_boards?: string
  show_statuses?: string
  show_board_filter?: boolean
  show_status_filter?: boolean
}

// What the embedding site allows: empty id lists mean all boards or statuses
export type RoadmapScope = {
  boardIds: number[]
  statusIds: number[]
  showBoardFilter: boolean
  showStatusFilter: boolean
}

export function validateEmbeddedRoadmapSearch(
  search: Record<string, unknown>,
): EmbeddedRoadmapSearch {
  return {
    ...validateRoadmapSearch(search),
    show_boards: asText(search.show_boards),
    show_statuses: asText(search.show_statuses),
    show_board_filter: asFlag(search.show_board_filter),
    show_status_filter: asFlag(search.show_status_filter),
  }
}

export function scopeFromEmbeddedSearch(search: EmbeddedRoadmapSearch): RoadmapScope {
  return {
    boardIds: parseIds(search.show_boards),
    statusIds: parseIds(search.show_statuses),
    showBoardFilter: search.show_board_filter !== false,
    showStatusFilter: search.show_status_filter !== false,
  }
}

// Columns and posts outside the scope are left out before the visitor's filters apply.
// With a board scope the server's post count no longer fits, so it becomes the visible count.
export function scopeRoadmap(columns: RoadmapColumn[], scope: RoadmapScope): RoadmapColumn[] {
  return columns
    .filter((column) => !scope.statusIds.length || scope.statusIds.includes(column.status.id))
    .map((column) => {
      if (!scope.boardIds.length) return column
      const posts = column.posts.filter((post) => scope.boardIds.includes(post.boardId))
      return { ...column, posts, postsCount: posts.length }
    })
}

// "true"/"false" from the URL (booleans too, in case the search was set in code)
function asFlag(value: unknown): boolean | undefined {
  if (value === true || value === 'true') return true
  if (value === false || value === 'false') return false
  return undefined
}
