// Helpers for URL search params. The router parses numeric values (?status=3, ?q=42)
// into numbers, so text params accept both.

export function asText(value: unknown): string | undefined {
  if (typeof value === 'number') return String(value)
  return typeof value === 'string' && value.trim() ? value : undefined
}

// "1,2,x" → [1, 2]; ignores empty parts and anything that is not a non-negative integer
export function parseIds(value: string | undefined): number[] {
  return (value ?? '')
    .split(',')
    .filter((part) => part.trim() !== '')
    .map(Number)
    .filter((id) => Number.isInteger(id) && id >= 0)
}

// [1, 2] → "1,2"; an empty list drops the param
export function formatIds(ids: number[]): string | undefined {
  return ids.length ? ids.join(',') : undefined
}

export function toggleId(ids: number[], id: number): number[] {
  return ids.includes(id) ? ids.filter((other) => other !== id) : [...ids, id]
}
