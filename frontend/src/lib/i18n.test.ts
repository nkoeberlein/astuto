import { describe, expect, it } from 'vitest'
import { textDirection, translate } from './i18n'

const translations = {
  board: { sort_by_box: { newest: 'Newest' } },
  post: { greeting: 'Hello %{name}' },
  time: { days: { one: '1 day ago', other: '%{count} days ago' } },
}

describe('translate', () => {
  it('looks up nested keys', () => {
    expect(translate(translations, 'board.sort_by_box.newest')).toBe('Newest')
  })

  it('interpolates Rails-style variables', () => {
    expect(translate(translations, 'post.greeting', { name: 'Ada' })).toBe('Hello Ada')
  })

  it('pluralizes with count', () => {
    expect(translate(translations, 'time.days', { count: 1 })).toBe('1 day ago')
    expect(translate(translations, 'time.days', { count: 3 })).toBe('3 days ago')
  })

  it('returns the key when a translation is missing', () => {
    expect(translate(translations, 'board.missing')).toBe('board.missing')
    expect(translate(translations, 'board.sort_by_box')).toBe('board.sort_by_box')
  })
})

describe('textDirection', () => {
  it('knows right-to-left languages, also with a region', () => {
    expect(textDirection('ar')).toBe('rtl')
    expect(textDirection('he-IL')).toBe('rtl')
    expect(textDirection('de')).toBe('ltr')
    expect(textDirection('zh-CN')).toBe('ltr')
  })
})
