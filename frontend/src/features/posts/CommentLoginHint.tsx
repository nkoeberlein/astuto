import { Link } from '@tanstack/react-router'
import { useLoginRedirect } from '@/features/auth/redirect'
import { useI18n } from '@/lib/i18n'

// Shown instead of the comment form to visitors; returns to the post after login
export function CommentLoginHint() {
  const { t } = useI18n()
  const loginRedirect = useLoginRedirect()

  return (
    <p className="text-sm text-muted-foreground">
      <Link to="/login" search={{ redirect: loginRedirect }} className="text-primary underline">
        {t('post.new_comment.not_logged_in')}
      </Link>
    </p>
  )
}
