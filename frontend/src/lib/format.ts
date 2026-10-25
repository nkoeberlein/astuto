const UNITS: [Intl.RelativeTimeFormatUnit, number][] = [
  ['year', 365 * 24 * 3600],
  ['month', 30 * 24 * 3600],
  ['week', 7 * 24 * 3600],
  ['day', 24 * 3600],
  ['hour', 3600],
  ['minute', 60],
]

// "3 days ago" in the given locale
export function formatRelativeTime(iso: string, locale: string, now = Date.now()): string {
  const seconds = Math.round((new Date(iso).getTime() - now) / 1000)
  const format = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' })
  for (const [unit, size] of UNITS) {
    if (Math.abs(seconds) >= size) return format.format(Math.round(seconds / size), unit)
  }
  return format.format(seconds, 'second')
}

// Black or white text, whichever reads better on the given hex background
export function readableTextColor(hex: string): string {
  const match = /^#?([0-9a-f]{6})$/i.exec(hex)
  if (!match?.[1]) return '#000000'
  const value = Number.parseInt(match[1], 16)
  const [r, g, b] = [value >> 16, (value >> 8) & 0xff, value & 0xff]
  return (r * 299 + g * 587 + b * 114) / 1000 > 150 ? '#000000' : '#ffffff'
}
