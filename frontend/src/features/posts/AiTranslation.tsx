import { Languages } from 'lucide-react'
import type { ReactNode } from 'react'
import { useTranslateComment, useTranslatePost } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Markdown } from '@/components/Markdown'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'

type ToggleProps = {
  pending: boolean
  shown: boolean
  onTranslate: () => void
  onHide: () => void
}

// "Translate" link; after a translation it hides it again
export function TranslateButton({ pending, shown, onTranslate, onHide }: ToggleProps) {
  const { t } = useI18n()
  return (
    <Button
      type="button"
      variant="link"
      size="sm"
      className="h-auto gap-1 p-0 text-xs text-muted-foreground hover:text-foreground"
      disabled={pending}
      title={t('post.ai_translation.hint')}
      onClick={shown ? onHide : onTranslate}
    >
      <Languages className="size-3" aria-hidden />
      {pending
        ? t('post.ai_translation.loading')
        : shown
          ? t('post.ai_translation.hide')
          : t('post.ai_translation.button')}
    </Button>
  )
}

// The translation next to the original, marked as machine-made
export function TranslationBox({ children }: { children: ReactNode }) {
  const { t } = useI18n()
  return (
    <div aria-live="polite" className="space-y-1 rounded-md bg-muted p-3 text-sm">
      <p className="text-xs font-medium text-muted-foreground">{t('post.ai_translation.label')}</p>
      {children}
    </div>
  )
}

export function PostTranslation({ postSlug }: { postSlug: string }) {
  const translate = useTranslatePost(postSlug)
  return (
    <div className="space-y-2">
      <TranslateButton
        pending={translate.isPending}
        shown={Boolean(translate.data)}
        onTranslate={() => translate.mutate()}
        onHide={() => translate.reset()}
      />
      <FormError error={translate.error} />
      {translate.data && (
        <TranslationBox>
          <p className="font-semibold">{translate.data.title}</p>
          {translate.data.description && <Markdown>{translate.data.description}</Markdown>}
        </TranslationBox>
      )}
    </div>
  )
}

// For comments: the button goes into the action row, the result below the comment
export function useCommentTranslation(postSlug: string, commentId: number) {
  const translate = useTranslateComment(postSlug, commentId)
  const button = (
    <TranslateButton
      pending={translate.isPending}
      shown={Boolean(translate.data)}
      onTranslate={() => translate.mutate()}
      onHide={() => translate.reset()}
    />
  )
  const result = (
    <>
      <FormError error={translate.error} />
      {translate.data && (
        <TranslationBox>
          <Markdown>{translate.data.body}</Markdown>
        </TranslationBox>
      )}
    </>
  )
  return { button, result }
}
