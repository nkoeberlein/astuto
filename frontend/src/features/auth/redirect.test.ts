import { describe, expect, it } from 'vitest'
import { oauthStartUrl, safeRedirect } from './redirect'

describe('safeRedirect', () => {
  it('accepts paths inside the app', () => {
    expect(safeRedirect('/')).toBe('/')
    expect(safeRedirect('/posts/dark-mode?sort=new')).toBe('/posts/dark-mode?sort=new')
  })

  it('rejects other hosts and non-strings', () => {
    for (const value of [
      '//evil.com',
      '/\\evil.com',
      'evil.com',
      'https://evil.com',
      'javascript:alert(1)',
      '/a\nb',
      '',
      undefined,
      42,
    ]) {
      expect(safeRedirect(value)).toBeUndefined()
    }
  })
})

describe('oauthStartUrl', () => {
  it('adds the return target with the basepath', () => {
    const url = new URL(
      oauthStartUrl('https://acme.example.com/o_auths/1/start?reason=login', '/posts/a', '/next'),
    )
    expect(url.searchParams.get('reason')).toBe('login')
    expect(url.searchParams.get('return_to')).toBe('/next/posts/a')
  })

  it('falls back to the app root', () => {
    const url = new URL(
      oauthStartUrl('https://acme.example.com/o_auths/1/start?reason=login', undefined, '/next'),
    )
    expect(url.searchParams.get('return_to')).toBe('/next/')
  })
})
