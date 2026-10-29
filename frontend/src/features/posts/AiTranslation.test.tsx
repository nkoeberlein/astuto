import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { I18nProvider } from '@/lib/i18n'
import { PostTranslation } from './AiTranslation'

const mutation = {
  mutate: vi.fn(),
  reset: vi.fn(),
  isPending: false,
  error: null as Error | null,
  data: undefined as { title: string; description: string | null; locale: string } | undefined,
}

vi.mock('@/api/mutations', () => ({
  useTranslatePost: () => mutation,
  useTranslateComment: () => mutation,
}))

// Same keys as config/locales/en.yml
const translations = {
  post: {
    ai_translation: {
      button: 'Translate',
      loading: 'Translating…',
      hide: 'Hide translation',
      label: 'AI translation',
      hint: 'Sent to the AI provider.',
    },
  },
}

const renderTranslation = () =>
  render(
    <I18nProvider locale="en" translations={translations}>
      <PostTranslation postSlug="dunkler-modus" />
    </I18nProvider>,
  )

describe('PostTranslation', () => {
  beforeEach(() => {
    Object.assign(mutation, {
      mutate: vi.fn(),
      reset: vi.fn(),
      isPending: false,
      error: null,
      data: undefined,
    })
  })

  it('requests a translation on click and tells where the text goes', () => {
    renderTranslation()
    const button = screen.getByRole('button', { name: 'Translate' })
    expect(button).toHaveAttribute('title', 'Sent to the AI provider.')

    fireEvent.click(button)
    expect(mutation.mutate).toHaveBeenCalledOnce()
  })

  it('shows the translation marked as AI-made and hides it again', () => {
    mutation.data = { title: 'Dark mode', description: '**Please**', locale: 'en' }
    renderTranslation()

    expect(screen.getByText('AI translation')).toBeInTheDocument()
    expect(screen.getByText('Dark mode')).toBeInTheDocument()
    expect(screen.getByText('Please').tagName).toBe('STRONG')

    fireEvent.click(screen.getByRole('button', { name: 'Hide translation' }))
    expect(mutation.reset).toHaveBeenCalledOnce()
  })

  it('shows the server error', () => {
    mutation.error = new Error('AI provider failed')
    renderTranslation()

    expect(screen.getByRole('alert')).toHaveTextContent('AI provider failed')
  })
})
