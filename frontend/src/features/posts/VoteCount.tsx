import { ChevronUp } from 'lucide-react'
import { cn } from '@/lib/utils'

// Display only for now; voting comes with the write endpoints
export function VoteCount(props: { count: number; liked: boolean; label: string }) {
  return (
    <div
      className={cn(
        'flex w-12 shrink-0 flex-col items-center rounded-lg border py-1.5 text-sm font-semibold transition-colors',
        props.liked
          ? 'border-primary bg-primary/10 text-primary shadow-2xs'
          : 'bg-muted/40 text-foreground',
      )}
      title={props.label}
    >
      <ChevronUp className="size-4" aria-hidden />
      <span>{props.count}</span>
    </div>
  )
}
