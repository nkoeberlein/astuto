import type { PostStatus } from '@/api/client'
import { Badge } from '@/components/ui/badge'
import { readableTextColor } from '@/lib/format'

export function StatusBadge({ status }: { status: PostStatus | undefined }) {
  if (!status) return null
  return (
    <Badge
      className="border-transparent"
      style={{ backgroundColor: status.color, color: readableTextColor(status.color) }}
    >
      {status.name}
    </Badge>
  )
}
