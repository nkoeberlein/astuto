import { useQuery } from '@tanstack/react-query'
import { tagsQuery } from '@/api/queries'
import { FilterChip } from '@/components/FilterChip'
import { useI18n } from '@/lib/i18n'
import { toggleId } from '@/lib/search-params'

// Moderators: tags of a post, one toggle per tag (Site settings › Tags)
export function TagPicker(props: {
  tagIds: number[]
  onChange: (tagIds: number[]) => void
  disabled?: boolean
}) {
  const { t } = useI18n()
  const { data: tags = [] } = useQuery(tagsQuery)
  if (tags.length === 0) return null

  return (
    <fieldset className="space-y-1.5" disabled={props.disabled}>
      <legend className="text-xs font-medium text-muted-foreground">{t('post.tags.title')}</legend>
      <div className="flex flex-wrap gap-1.5">
        {tags.map((tag) => (
          <FilterChip
            key={tag.id}
            active={props.tagIds.includes(tag.id)}
            onClick={() => props.onChange(toggleId(props.tagIds, tag.id))}
            color={tag.color}
          >
            {tag.name}
          </FilterChip>
        ))}
      </div>
    </fieldset>
  )
}
