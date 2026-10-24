import { type PostFilters, SORT_OPTIONS, type SortBy } from '@/api/queries'

// URL search params of the board page, e.g. ?q=dark&sort=newest&status=1,2
export type BoardSearch = { q?: string; sort?: SortBy; status?: string }

// The router parses numeric values (?status=3, ?q=42) into numbers
function asText(value: unknown): string | undefined {
  if (typeof value === 'number') return String(value)
  return typeof value === 'string' && value.trim() ? value : undefined
}

export function validateBoardSearch(search: Record<string, unknown>): BoardSearch {
  const sort = SORT_OPTIONS.find((option) => option === search.sort)
  return { q: asText(search.q), sort, status: asText(search.status) }
}

// Without an explicit sort param the tenant's default sorting applies
export function filtersFromSearch(
  search: BoardSearch,
  defaultSort: SortBy = 'trending',
): PostFilters {
  const statusIds = (search.status ?? '')
    .split(',')
    .filter((part) => part.trim() !== '')
    .map(Number)
    .filter((id) => Number.isInteger(id) && id >= 0)
  return { search: search.q ?? '', sortBy: search.sort ?? defaultSort, statusIds }
}
