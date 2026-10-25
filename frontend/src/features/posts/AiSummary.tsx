import { Sparkles } from 'lucide-react'
import { useSummarizePost } from '@/api/mutations'
import { FormError } from '@/components/FormError'
import { Markdown } from '@/components/Markdown'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'

// Moderators can ask the configured AI provider for a short summary of the discussion
export function AiSummary({ postSlug }: { postSlug: string }) {
  const { t } = useI18n()
  const summarize = useSummarizePost(postSlug)

  return (
    <section aria-label={t('post.ai_summary.title')} className="space-y-2">
      <Button
        type="button"
        variant="outline"
        size="sm"
        className="w-full gap-1.5"
        disabled={summarize.isPending}
        onClick={() => summarize.mutate()}
      >
        <Sparkles className="size-3.5" aria-hidden />
        {summarize.isPending ? t('post.ai_summary.loading') : t('post.ai_summary.button')}
      </Button>
      <p className="text-xs text-muted-foreground">{t('post.ai_summary.hint')}</p>
      <FormError error={summarize.error} />
      {summarize.data && (
        <div aria-live="polite" className="rounded-md bg-muted p-3 text-sm">
          <Markdown>{summarize.data.summary}</Markdown>
        </div>
      )}
    </section>
  )
}
