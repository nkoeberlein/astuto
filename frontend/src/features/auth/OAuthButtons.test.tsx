import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import type { OAuthProvider } from '@/api/client'
import { I18nProvider } from '@/lib/i18n'
import { OAuthButtons } from './OAuthButtons'

const translations = {
  common: {
    words: { or: 'or' },
    forms: {
      auth: {
        log_in_with: 'Log in with %{o_auth}',
        sign_up_with: 'Sign up with %{o_auth}',
      },
    },
  },
}

const providers: OAuthProvider[] = [
  {
    id: 1,
    name: 'GitHub',
    logo: 'https://example.com/github.svg',
    startUrl: 'https://acme.example.com/o_auths/1/start?reason=login',
  },
  {
    id: 2,
    name: 'Keycloak',
    logo: null,
    startUrl: 'https://acme.example.com/o_auths/2/start?reason=login',
  },
]

describe('OAuthButtons', () => {
  it('renders nothing when no providers are enabled', () => {
    const { container } = render(
      <I18nProvider locale="en" translations={translations}>
        <OAuthButtons providers={[]} mode="login" showDivider />
      </I18nProvider>,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('renders login links and divider for enabled OAuth providers', () => {
    render(
      <I18nProvider locale="en" translations={translations}>
        <OAuthButtons providers={providers} mode="login" showDivider redirect="/posts/dark-mode" />
      </I18nProvider>,
    )
    expect(screen.getByText('or')).toBeInTheDocument()
    const githubLink = screen.getByRole('link', { name: 'Log in with GitHub' })
    expect(githubLink).toHaveAttribute(
      'href',
      'https://acme.example.com/o_auths/1/start?reason=login&return_to=%2Fposts%2Fdark-mode',
    )
    expect(screen.getByRole('link', { name: 'Log in with Keycloak' })).toBeInTheDocument()
  })

  it('renders sign-up labels when mode is signup', () => {
    render(
      <I18nProvider locale="en" translations={translations}>
        <OAuthButtons providers={providers} mode="signup" />
      </I18nProvider>,
    )
    expect(screen.getByRole('link', { name: 'Sign up with GitHub' })).toBeInTheDocument()
  })
})
