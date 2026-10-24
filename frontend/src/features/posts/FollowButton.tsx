import { Bell, BellOff } from 'lucide-react'
import { useFollow } from '@/api/mutations'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n'

export function FollowButton({ postSlug, followed }: { postSlug: string; followed: boolean }) {
  const { t } = useI18n()
  const follow = useFollow(postSlug)
  const Icon = followed ? BellOff : Bell

  return (
    <div className="flex flex-wrap items-center gap-3 text-sm">
      <Button
        variant={followed ? 'secondary' : 'outline'}
        size="sm"
        aria-pressed={followed}
        disabled={follow.isPending}
        onClick={() => follow.mutate(!followed)}
      >
        <Icon className="size-4" aria-hidden /> {t('post.action_box.follow_button')}
      </Button>
      <span className="text-muted-foreground">
        {t(
          followed
            ? 'post.action_box.following_description'
            : 'post.action_box.not_following_description',
        )}
      </span>
    </div>
  )
}
