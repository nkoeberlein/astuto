import { describe, expect, it } from 'vitest'
import type { ModerationUser, ModerationUserPage } from '@/api/client'
import {
  confirmationKey,
  filtersFromUsersSearch,
  replaceUser,
  usersSearchFromFilters,
  validateUsersSearch,
} from './users'

const user = (id: number, changes: Partial<ModerationUser> = {}): ModerationUser => ({
  id,
  email: `user${id}@example.com`,
  fullName: `User ${id}`,
  avatarUrl: 'https://example.com/a.png',
  role: 'user',
  status: 'active',
  createdAt: '2026-10-28T10:00:00Z',
  canChangeStatus: true,
  canChangeRole: true,
  ...changes,
})

describe('users search params', () => {
  it('keeps known roles and statuses only', () => {
    expect(validateUsersSearch({ q: 'ada', role: 'moderator', status: 'gone' })).toEqual({
      q: 'ada',
      role: 'moderator',
      status: undefined,
    })
  })

  it('round-trips filters and drops an empty search', () => {
    const filters = filtersFromUsersSearch({ q: '  ', status: 'blocked' })
    expect(filters).toEqual({ search: '', role: undefined, status: 'blocked' })
    expect(usersSearchFromFilters(filters)).toEqual({
      q: undefined,
      role: undefined,
      status: 'blocked',
    })
  })
})

describe('replaceUser', () => {
  it('swaps the updated user in every cached page', () => {
    const page = (users: ModerationUser[]): ModerationUserPage => ({
      users,
      page: 1,
      hasMore: false,
      counts: { total: 3, active: 3, blocked: 0, deleted: 0 },
    })
    const data = { pages: [page([user(1), user(2)]), page([user(3)])], pageParams: [1, 2] }
    const result = replaceUser(data, user(3, { status: 'blocked' }))
    expect(result.pages[1]?.users[0]?.status).toBe('blocked')
    expect(result.pages[0]?.users).toEqual(data.pages[0]?.users)
  })
})

describe('confirmationKey', () => {
  it('asks before blocking, unblocking and granting more rights', () => {
    expect(confirmationKey(user(1), { status: 'blocked' })).toBe(
      'moderation.users.block_confirmation',
    )
    expect(confirmationKey(user(1), { status: 'active' })).toBe(
      'moderation.users.unblock_confirmation',
    )
    expect(confirmationKey(user(1), { role: 'admin' })).toBe(
      'moderation.users.role_to_admin_confirmation',
    )
    expect(confirmationKey(user(1, { role: 'admin' }), { role: 'user' })).toBeUndefined()
    expect(confirmationKey(user(1, { role: 'moderator' }), { role: 'moderator' })).toBeUndefined()
  })
})
