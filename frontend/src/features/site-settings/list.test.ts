import { describe, expect, it } from 'vitest'
import { moveId } from './list'

describe('moveId', () => {
  it('swaps with the neighbour', () => {
    expect(moveId([1, 2, 3], 1, -1)).toEqual([2, 1, 3])
    expect(moveId([1, 2, 3], 1, 1)).toEqual([1, 3, 2])
  })

  it('stays put at the ends and for unknown positions', () => {
    const ids = [1, 2, 3]
    expect(moveId(ids, 0, -1)).toBe(ids)
    expect(moveId(ids, 2, 1)).toBe(ids)
    expect(moveId(ids, 5, -1)).toBe(ids)
  })
})
