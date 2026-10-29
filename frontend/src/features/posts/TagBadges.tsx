import { useQuery } from '@tanstack/react-query'
import { tagsQuery } from '@/api/queries'

// The tags of a post as small labels, in the order of Site settings › Tags
export function TagBadges({ tagIds }: { tagIds: number[] }) {
  const { data: tags } = useQuery({ ...tagsQuery, enabled: tagIds.length > 0 })
  const shown = (tags ?? []).filter((tag) => tagIds.includes(tag.id))
  if (shown.length === 0) return null

  return (
    <ul className="flex flex-wrap gap-1.5">
      {shown.map((tag) => (
        <li
          key={tag.id}
          className="flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs text-muted-foreground"
        >
          <span
            className="size-1.5 rounded-full"
            style={{ backgroundColor: tag.color }}
            aria-hidden
          />
          {tag.name}
        </li>
      ))}
    </ul>
  )
}
