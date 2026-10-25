import { useVote } from '@/api/mutations'
import { useI18n } from '@/lib/i18n'
import { VoteCount } from './VoteCount'

type Props = {
  post: { id: number; slug: string; liked: boolean; likesCount: number }
  signedIn: boolean
}

// Toggles the current user's vote. Visitors are sent to the login page.
export function VoteButton({ post, signedIn }: Props) {
  const { t } = useI18n()
  const vote = useVote(post)
  const label = `${t('post.likes_box.title')}: ${post.likesCount}`
  const count = <VoteCount count={post.likesCount} liked={post.liked} label={label} />

  if (!signedIn) {
    return (
      <a
        href="/users/sign_in"
        title={t('header.log_in')}
        aria-label={`${label} – ${t('header.log_in')}`}
        className="rounded-md hover:bg-accent"
      >
        {count}
      </a>
    )
  }

  return (
    <button
      type="button"
      aria-pressed={post.liked}
      aria-label={label}
      disabled={vote.isPending}
      onClick={() => vote.mutate(!post.liked)}
      className="rounded-md hover:bg-accent disabled:opacity-70"
    >
      {count}
    </button>
  )
}
