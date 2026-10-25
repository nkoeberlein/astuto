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
