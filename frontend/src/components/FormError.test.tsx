import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { ApiError } from '@/api/client'
import { FormError } from './FormError'

describe('FormError', () => {
  it('announces the error message', () => {
    render(<FormError error={new ApiError(403, 'Not allowed')} />)
    expect(screen.getByRole('alert')).toHaveTextContent('Not allowed')
  })

  it('renders nothing without an error', () => {
    const { container } = render(<FormError error={null} />)
    expect(container).toBeEmptyDOMElement()
  })
})
