import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { I18nProvider } from '@/lib/i18n'
import { AiSummary } from './AiSummary'

const mutation = {
  mutate: vi.fn(),
  isPending: false,
  error: null as Error | null,
  data: undefined as { summary: string } | undefined,
}

vi.mock('@/api/mutations', () => ({ useSummarizePost: () => mutation }))

// Same keys as config/locales/en.yml
const translations = {
  post: {
    ai_summary: {
      title: 'AI summary',
      button: 'Summarize discussion',
      loading: 'Summarizing…',
      hint: 'Sent to the AI provider.',
    },
  },
}

const renderSummary = () =>
  render(
    <I18nProvider locale="en" translations={translations}>
      <AiSummary postSlug="dark-mode" />
    </I18nProvider>,
  )

describe('AiSummary', () => {
  beforeEach(() => {
    Object.assign(mutation, { mutate: vi.fn(), isPending: false, error: null, data: undefined })
  })

  it('requests a summary on click and tells where the data goes', () => {
    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: 'Summarize discussion' }))

    expect(mutation.mutate).toHaveBeenCalledOnce()
    expect(screen.getByText('Sent to the AI provider.')).toBeInTheDocument()
  })

  it('shows the summary as Markdown', () => {
    mutation.data = { summary: '- Users want a dark theme' }
    renderSummary()

    expect(screen.getByRole('listitem')).toHaveTextContent('Users want a dark theme')
  })

  it('shows the server error', () => {
    mutation.error = new Error('AI provider failed')
    renderSummary()

    expect(screen.getByRole('alert')).toHaveTextContent('AI provider failed')
  })
})
