import { describe, expect, it } from 'vitest'
import { formatRelativeTime, readableTextColor } from './format'

describe('formatRelativeTime', () => {
  const now = Date.parse('2026-10-24T12:00:00Z')

  it('formats past dates in the given locale', () => {
    expect(formatRelativeTime('2026-10-21T12:00:00Z', 'en', now)).toBe('3 days ago')
    expect(formatRelativeTime('2026-10-21T12:00:00Z', 'de', now)).toBe('vor 3 Tagen')
  })
})

describe('readableTextColor', () => {
  it('picks dark text on light backgrounds and vice versa', () => {
    expect(readableTextColor('#ffffff')).toBe('#000000')
    expect(readableTextColor('#1f2937')).toBe('#ffffff')
    expect(readableTextColor('not-a-color')).toBe('#000000')
  })
})
