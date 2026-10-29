import { useQuery } from '@tanstack/react-query'
import { Wand2 } from 'lucide-react'
import type { Board, Post } from '@/api/client'
import { useSuggestBoardAndTags } from '@/api/mutations'
import { tagsQuery } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'

// Moderators: the AI provider proposes a board and tags from the existing ones; nothing
// changes until "Apply" (tags are added to the ones the post has)
export function AiSuggestion(props: {
  post: Post
  boards: Board[]
  onApply: (changes: { boardId?: number; tagIds?: number[] }) => void
}) {
  const { t } = useI18n()
  const suggest = useSuggestBoardAndTags(props.post.slug)
  const { data: tags = [] } = useQuery(tagsQuery)
  const suggestion = suggest.data
  const board =
    suggestion?.boardId && suggestion.boardId !== props.post.boardId
      ? props.boards.find((candidate) => candidate.id === suggestion.boardId)
      : undefined
  const newTags = tags.filter(
    (tag) => suggestion?.tagIds.includes(tag.id) && !props.post.tagIds.includes(tag.id),
  )

  return (
    <section aria-label={t('post.ai_suggestion.button')} className="space-y-2">
      <Button
        type="button"
        variant="outline"
        size="sm"
        className="w-full gap-1.5"
        disabled={suggest.isPending}
        onClick={() => suggest.mutate()}
      >
        <Wand2 className="size-3.5" aria-hidden />
        {suggest.isPending ? t('post.ai_suggestion.loading') : t('post.ai_suggestion.button')}
      </Button>
      <p className="text-xs text-muted-foreground">{t('post.ai_suggestion.hint')}</p>
      <FormError error={suggest.error} />
      {suggestion && (
        <div aria-live="polite" className="space-y-2 rounded-md bg-muted p-3 text-sm">
          {!board && newTags.length === 0 ? (
            <p>{t('post.ai_suggestion.none')}</p>
          ) : (
            <>
              {board && (
                <p>
                  {t('post.ai_suggestion.board')} <strong>{board.name}</strong>
                </p>
              )}
              {newTags.length > 0 && (
                <p>
                  {t('post.ai_suggestion.tags')}{' '}
                  <strong>{newTags.map((tag) => tag.name).join(', ')}</strong>
                </p>
              )}
              <Button
                type="button"
                size="sm"
                onClick={() => {
                  props.onApply({
                    ...(board ? { boardId: board.id } : {}),
                    ...(newTags.length
                      ? { tagIds: [...props.post.tagIds, ...newTags.map((tag) => tag.id)] }
                      : {}),
                  })
                  suggest.reset()
                }}
              >
                {t('post.ai_suggestion.apply')}
              </Button>
            </>
          )}
        </div>
      )}
    </section>
  )
}
