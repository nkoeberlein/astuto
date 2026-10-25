import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { SiteFooter } from '@/features/layout/SiteFooter'
import { I18nProvider } from '@/lib/i18n'
import { EvoBadge, EvoLogo } from './EvoLogo'

describe('EvoLogo & branding', () => {
  it('renders the inline Astuto Evo fox SVG mark and EVO badge', () => {
    const { container } = render(
      <div>
        <EvoLogo />
        <EvoBadge />
      </div>,
    )
    expect(container.querySelector('svg')).toBeInTheDocument()
    expect(screen.getByText('Evo')).toBeInTheDocument()
  })

  it('renders Powered by Astuto Evolution (Evo) in SiteFooter', () => {
    render(
      <I18nProvider locale="en" translations={{ common: { powered_by: 'Powered by' } }}>
        <SiteFooter showPoweredBy={true} />
      </I18nProvider>,
    )
    expect(screen.getByText(/Powered by Astuto Evolution/)).toBeInTheDocument()
    expect(screen.getByText('Evo')).toBeInTheDocument()
  })
})
