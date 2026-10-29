import { describe, expect, it } from 'vitest'
import { readFlash } from './FlashMessages'

const docWith = (content: string | null) => {
  const doc = document.implementation.createHTMLDocument()
  if (content !== null) {
    const meta = doc.createElement('meta')
    meta.name = 'astuto-flash'
    meta.content = content
    doc.head.append(meta)
  }
  return doc
}

describe('readFlash', () => {
  it('reads notice and alert from the meta tag', () => {
    expect(readFlash(docWith('{"notice":"Confirmed","alert":"Oops"}'))).toEqual({
      notice: 'Confirmed',
      alert: 'Oops',
    })
  })

  it('ignores a missing tag, invalid JSON and non-text values', () => {
    expect(readFlash(docWith(null))).toEqual({})
    expect(readFlash(docWith('{broken'))).toEqual({})
    expect(readFlash(docWith('{"notice":42}'))).toEqual({ notice: undefined, alert: undefined })
  })
})
