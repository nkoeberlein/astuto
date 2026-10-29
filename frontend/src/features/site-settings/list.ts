// Ids after moving the item at `index` one step up (-1) or down (+1); unchanged at the ends
export function moveId(ids: number[], index: number, step: -1 | 1): number[] {
  const target = index + step
  if (index < 0 || index >= ids.length || target < 0 || target >= ids.length) return ids
  const next = [...ids]
  ;[next[index], next[target]] = [next[target] as number, next[index] as number]
  return next
}
