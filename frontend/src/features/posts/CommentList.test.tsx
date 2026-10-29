import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import type { Comment, Session } from '@/api/client'
import { I18nProvider } from '@/lib/i18n'
import { CommentList, groupComments } from './CommentList'

const comment = (
  id: number,
  parentId: number | null,
  overrides: Partial<Comment> = {},
): Comment => ({
  id,
  parentId,
  body: `Comment ${id}`,
  isPostUpdate: false,
  author: { id: 1, fullName: 'Ada Lovelace', avatarUrl: 'https://example.com/a.png' },
  createdAt: '2026-10-20T10:00:00Z',
  updatedAt: '2026-10-20T10:00:00Z',
  ...overrides,
})

// Same keys as config/locales/en.yml
const translations = {
  post: {
    comments: { empty: 'No comments', post_update_badge: 'Update', reply_button: 'Reply' },
  },
  common: { buttons: { edit: 'Edit', delete: 'Delete', update: 'Save', cancel: 'Cancel' } },
}

describe('groupComments', () => {
  it('nests replies under their parent', () => {
    const groups = groupComments([comment(1, null), comment(2, 1), comment(3, null)])
    expect(groups.map((g) => [g.comment.id, g.replies.map((r) => r.id)])).toEqual([
      [1, [2]],
      [3, []],
    ])
  })
})

describe('CommentList', () => {
  const renderList = (
    comments: Comment[],
    options: { postSlug?: string; currentUser?: Session['user'] } = {},
  ) => {
    const queryClient = new QueryClient()
    return render(
      <QueryClientProvider client={queryClient}>
        <I18nProvider locale="en" translations={translations}>
          <CommentList comments={comments} {...options} />
        </I18nProvider>
      </QueryClientProvider>,
    )
  }

  it('renders comments with author and update badge', () => {
    renderList([comment(1, null, { isPostUpdate: true })])
    expect(screen.getByText('Comment 1')).toBeInTheDocument()
    expect(screen.getByText('Ada Lovelace')).toBeInTheDocument()
    expect(screen.getByText('Update')).toBeInTheDocument()
  })

  it('shows edit and delete actions for the comment author or moderator', () => {
    renderList([comment(1, null)], {
      postSlug: 'my-post',
      currentUser: {
        id: 1,
        email: 'ada@example.com',
        fullName: 'Ada Lovelace',
        role: 'user',
        avatarUrl: 'https://example.com/a.png',
        twoFactorSetupRequired: false,
      },
    })
    expect(screen.getByText('Edit')).toBeInTheDocument()
    expect(screen.getByText('Delete')).toBeInTheDocument()
  })

  it('shows an empty state', () => {
    renderList([])
    expect(screen.getByText('No comments')).toBeInTheDocument()
  })
})
