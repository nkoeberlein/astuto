import type { Session } from '@/api/client'

type User = NonNullable<Session['user']>

// Moderators, admins and owners may moderate feedback (User#moderator? on the server)
export function isModerator(user: User | null | undefined): user is User {
  return user != null && ['moderator', 'admin', 'owner'].includes(user.role)
}

// Admins and owners manage site settings (User#admin? on the server)
export function isAdmin(user: User | null | undefined): user is User {
  return user != null && ['admin', 'owner'].includes(user.role)
}
