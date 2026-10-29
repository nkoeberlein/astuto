import type { InfiniteData } from '@tanstack/react-query'
import type { ModerationUser, ModerationUserPage, UserRole, UserStatus } from '@/api/client'
import type { UserFilters } from '@/api/queries'
import { asText } from '@/lib/search-params'

export const USER_ROLES: UserRole[] = ['owner', 'admin', 'moderator', 'user']
export const USER_STATUSES: UserStatus[] = ['active', 'pending_approval', 'blocked', 'deleted']
// Roles an admin can give; nobody can make someone owner
export type AssignableRole = Exclude<UserRole, 'owner'>
export const ASSIGNABLE_ROLES: AssignableRole[] = ['user', 'moderator', 'admin']

// URL search params of the users page, e.g. ?q=ada&role=moderator&status=blocked
export type UsersSearch = { q?: string; role?: UserRole; status?: UserStatus }

export function validateUsersSearch(search: Record<string, unknown>): UsersSearch {
  return {
    q: asText(search.q),
    role: USER_ROLES.find((role) => role === search.role),
    status: USER_STATUSES.find((status) => status === search.status),
  }
}

export function filtersFromUsersSearch(search: UsersSearch): UserFilters {
  return { search: search.q?.trim() ?? '', role: search.role, status: search.status }
}

export function usersSearchFromFilters(filters: UserFilters): UsersSearch {
  return { q: filters.search || undefined, role: filters.role, status: filters.status }
}

// Cached pages with one user replaced by the server's answer
export function replaceUser(
  data: InfiniteData<ModerationUserPage>,
  updated: ModerationUser,
): InfiniteData<ModerationUserPage> {
  return {
    ...data,
    pages: data.pages.map((page) => ({
      ...page,
      users: page.users.map((user) => (user.id === updated.id ? updated : user)),
    })),
  }
}

// Question before a change that gives someone more rights or locks them out
export function confirmationKey(
  user: ModerationUser,
  change: { role?: UserRole; status?: UserStatus },
): string | undefined {
  if (change.status === 'blocked') return 'moderation.users.block_confirmation'
  // Approving a new account needs no question; it can be blocked again
  if (change.status === 'active' && user.status === 'pending_approval') return undefined
  if (change.status === 'active') return 'moderation.users.unblock_confirmation'
  if (change.role === user.role) return undefined
  if (change.role === 'moderator') return 'moderation.users.role_to_moderator_confirmation'
  if (change.role === 'admin') return 'moderation.users.role_to_admin_confirmation'
  return undefined
}
