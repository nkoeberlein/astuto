import { describe, expect, it } from 'vitest'
import { excerpt } from './text'

describe('excerpt', () => {
  it('strips Markdown marks and shortens long text', () => {
    expect(excerpt('## **Dark** mode\n\n- for [all](https://x.y) pages ![logo](a.png)')).toBe(
      'Dark mode for all pages logo',
    )
    expect(excerpt('Buy now! (really)')).toBe('Buy now! (really)')
    expect(excerpt('a'.repeat(250))).toHaveLength(201)
    expect(excerpt(null)).toBe('')
  })
})
