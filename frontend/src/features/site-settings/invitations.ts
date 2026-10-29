import type { Invitation } from '@/api/client'

export const MAX_INVITATIONS = 20
export const LINK_PLACEHOLDER = '%link%'

// "a@x.de, b@x.de,,c@x.de" → ["a@x.de", "b@x.de", "c@x.de"] (no duplicates)
export function parseEmailList(text: string): string[] {
  return [
    ...new Set(
      text
        .split(/[,;\s]+/)
        .map((email) => email.trim())
        .filter(Boolean),
    ),
  ]
}

export type InvitationFilter = 'all' | Invitation['status']

export function filterInvitations(invitations: Invitation[], filter: InvitationFilter) {
  return filter === 'all' ? invitations : invitations.filter((i) => i.status === filter)
}
