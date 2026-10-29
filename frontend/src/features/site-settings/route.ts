import type { QueryClient } from '@tanstack/react-query'
import { type ParsedLocation, redirect } from '@tanstack/react-router'
import { sessionQuery } from '@/api/queries'
import { isAdmin } from '@/lib/roles'

// Loader guard of the site settings pages: visitors log in first, non-admins go home
export async function requireAdmin(queryClient: QueryClient, location: ParsedLocation) {
  const session = await queryClient.ensureQueryData(sessionQuery)
  if (!session.user) throw redirect({ to: '/login', search: { redirect: location.href } })
  if (!isAdmin(session.user)) throw redirect({ to: '/' })
  return session
}
