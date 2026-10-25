import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

// Toggle button for filter lists (statuses, boards), optionally with a color dot
export function FilterChip(props: {
  active: boolean
  onClick: () => void
  color?: string
  children: ReactNode
}) {
  return (
    <button
      type="button"
      aria-pressed={props.active}
      onClick={props.onClick}
      className={cn(
        'flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs',
        props.active ? 'border-primary bg-primary/10' : 'text-muted-foreground hover:bg-accent',
      )}
    >
      {props.color && (
        <span className="size-2 rounded-full" style={{ backgroundColor: props.color }} />
      )}
      {props.children}
    </button>
  )
}
