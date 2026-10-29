import { describe, expect, it } from 'vitest'
import type { Invitation } from '@/api/client'
import { filterInvitations, parseEmailList } from './invitations'

describe('parseEmailList', () => {
  it('splits on commas, semicolons and whitespace and drops duplicates', () => {
    expect(parseEmailList(' a@x.de, b@x.de;;\nc@x.de a@x.de ,')).toEqual([
      'a@x.de',
      'b@x.de',
      'c@x.de',
    ])
    expect(parseEmailList('  ')).toEqual([])
  })
})

describe('filterInvitations', () => {
  const invitation = (id: number, status: Invitation['status']): Invitation => ({
    id,
    email: `p${id}@x.de`,
    status,
    sentAt: '2026-10-01T10:00:00Z',
    acceptedAt: null,
  })
  const all = [invitation(1, 'pending'), invitation(2, 'accepted'), invitation(3, 'expired')]

  it('shows everything or one status', () => {
    expect(filterInvitations(all, 'all')).toHaveLength(3)
    expect(filterInvitations(all, 'accepted').map((i) => i.id)).toEqual([2])
  })
})
