import { ChevronUp } from 'lucide-react'
import { cn } from '@/lib/utils'

// Display only for now; voting comes with the write endpoints
export function VoteCount(props: { count: number; liked: boolean; label: string }) {
  return (
    <div
      className={cn(
        'flex w-12 shrink-0 flex-col items-center rounded-md border py-1 text-sm font-semibold',
        props.liked && 'border-primary text-primary',
      )}
      title={props.label}
    >
      <ChevronUp className="size-4" aria-hidden />
      <span>{props.count}</span>
    </div>
  )
}
