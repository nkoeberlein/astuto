import { describe, expect, it } from 'vitest'
import { filtersFromSearch, validateBoardSearch } from './search'

describe('board search params', () => {
  it('keeps valid values and drops unknown ones', () => {
    expect(validateBoardSearch({ q: 'dark mode', sort: 'newest', status: '1,2' })).toEqual({
      q: 'dark mode',
      sort: 'newest',
      status: '1,2',
    })
    expect(validateBoardSearch({ q: '  ', sort: 'random', status: true })).toEqual({
      q: undefined,
      sort: undefined,
      status: undefined,
    })
  })

  it('accepts values the router parsed as numbers', () => {
    expect(validateBoardSearch({ q: 42, status: 3 })).toEqual({
      q: '42',
      sort: undefined,
      status: '3',
    })
  })

  it('has no status filter without a status param', () => {
    expect(filtersFromSearch({}).statusIds).toEqual([])
  })

  it('turns search params into post filters', () => {
    expect(filtersFromSearch({ status: '0,3,x' })).toEqual({
      search: '',
      sortBy: 'trending',
      statusIds: [0, 3],
    })
  })
})
