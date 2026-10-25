import { type PostFilters, SORT_OPTIONS, type SortBy } from '@/api/queries'
import { asText, parseIds } from '@/lib/search-params'

// URL search params of the board page, e.g. ?q=dark&sort=newest&status=1,2
export type BoardSearch = { q?: string; sort?: SortBy; status?: string }

export function validateBoardSearch(search: Record<string, unknown>): BoardSearch {
  const sort = SORT_OPTIONS.find((option) => option === search.sort)
  return { q: asText(search.q), sort, status: asText(search.status) }
}

// Without an explicit sort param the tenant's default sorting applies
export function filtersFromSearch(
  search: BoardSearch,
  defaultSort: SortBy = 'trending',
): PostFilters {
  return {
    search: search.q ?? '',
    sortBy: search.sort ?? defaultSort,
    statusIds: parseIds(search.status),
  }
}
