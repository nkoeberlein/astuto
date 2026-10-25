import { describe, expect, it } from 'vitest'
import type { RoadmapColumn, RoadmapPost } from '@/api/client'
import {
  filterRoadmap,
  filtersFromRoadmapSearch,
  roadmapSearchFromFilters,
  validateRoadmapSearch,
} from './search'

const post = (id: number, boardId: number): RoadmapPost => ({
  id,
  slug: `post-${id}`,
  title: `Post ${id}`,
  boardId,
  likesCount: 0,
  commentsCount: 0,
  liked: false,
  updatedAt: '2026-10-20T10:00:00Z',
})

const column = (
  statusId: number,
  posts: RoadmapPost[],
  postsCount = posts.length,
): RoadmapColumn => ({
  status: {
    id: statusId,
    name: `Status ${statusId}`,
    color: '#000000',
    order: statusId,
    showInRoadmap: true,
  },
  posts,
  postsCount,
})

describe('roadmap search params', () => {
  it('keeps valid values and drops unknown ones', () => {
    expect(validateRoadmapSearch({ board: '1,2', status: 3, sort: 'recently_updated' })).toEqual({
      board: '1,2',
      status: '3',
      sort: 'recently_updated',
    })
    expect(validateRoadmapSearch({ board: ' ', sort: 'newest' })).toEqual({
      board: undefined,
      status: undefined,
      sort: undefined,
    })
  })

  it('round-trips filters and leaves defaults out of the URL', () => {
    const filters = filtersFromRoadmapSearch({ board: '2,x', status: '' })
    expect(filters).toEqual({ boardIds: [2], statusIds: [], sortBy: 'most_voted' })
    expect(roadmapSearchFromFilters(filters)).toEqual({
      board: '2',
      status: undefined,
      sort: undefined,
    })
  })
})

describe('filterRoadmap', () => {
  const columns = [column(1, [post(1, 10), post(2, 20)], 5), column(2, [post(3, 20)])]

  it('shows everything without filters and counts posts the server left out', () => {
    const result = filterRoadmap(columns, { boardIds: [], statusIds: [], sortBy: 'most_voted' })
    expect(result.map((c) => [c.status.id, c.posts.length, c.hiddenCount])).toEqual([
      [1, 2, 3],
      [2, 1, 0],
    ])
  })

  it('hides columns by status and posts by board', () => {
    const result = filterRoadmap(columns, { boardIds: [10], statusIds: [1], sortBy: 'most_voted' })
    expect(result).toHaveLength(1)
    expect(result[0]?.posts.map((p) => p.id)).toEqual([1])
    expect(result[0]?.postsCount).toBe(1)
    expect(result[0]?.hiddenCount).toBe(0)
  })
})
