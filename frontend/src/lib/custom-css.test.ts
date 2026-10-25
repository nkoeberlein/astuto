import { describe, expect, it } from 'vitest'
import { escapeCustomCss } from './custom-css'

describe('escapeCustomCss', () => {
  it('keeps ordinary CSS unchanged, including child selectors', () => {
    expect(escapeCustomCss('.header > a { color: #f00; }')).toBe('.header > a { color: #f00; }')
  })

  it('never lets a closing style tag through, even when nested', () => {
    for (const payload of [
      '</style><script>alert(1)</script>',
      '</STYLE ><script>alert(1)</script>',
      '</sty</stylele><script>alert(1)</script>',
    ]) {
      expect(escapeCustomCss(payload)).not.toContain('<')
    }
  })

  it('writes "<" as the CSS escape \\3c', () => {
    expect(escapeCustomCss('a::after { content: "<"; }')).toBe('a::after { content: "\\3c "; }')
  })
})
