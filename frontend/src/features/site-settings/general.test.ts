import { describe, expect, it } from 'vitest'
import type { GeneralSettings } from '@/api/client'
import { changedFields, draftFromSettings, formatCustomLinks, parseCustomLinks } from './general'

const settings: GeneralSettings = {
  siteName: 'Acme',
  siteLogo: null,
  siteFavicon: null,
  locale: 'en',
  customDomain: null,
  brandDisplay: 'name_and_logo',
  useBrowserLocale: false,
  rootBoardId: 0,
  defaultPostSorting: 'trending',
  customLinks: [{ label: 'Docs', url: 'https://example.com/docs' }],
  isPrivate: false,
  allowAnonymousFeedback: true,
  feedbackApprovalPolicy: 'anonymous_require_approval',
  loginOnlyWithOauth: false,
  logoLinksTo: 'root_page',
  logoCustomUrl: null,
  roadmapEnabled: true,
  showRoadmapInHeader: true,
  collapseBoardsInHeader: 'no_collapse',
  mailLogoSize: 64,
  showVoteCount: true,
  showVoteButtonInBoard: true,
  hideUnusedStatusesInFilterByStatus: false,
  showPoweredBy: true,
  customCss: null,
  emailRegistrationPolicy: 'all_allowed',
  allowedEmailDomains: null,
  multiTenancy: false,
  availableLocales: ['en', 'de'],
}

describe('general settings form', () => {
  it('leaves read-only fields out of the draft', () => {
    const draft = draftFromSettings(settings)
    expect(draft).not.toHaveProperty('multiTenancy')
    expect(draft).not.toHaveProperty('availableLocales')
  })

  it('sends only changed fields', () => {
    const original = draftFromSettings(settings)
    expect(changedFields(original, { ...original })).toEqual({})
    expect(
      changedFields(original, {
        ...original,
        siteName: 'Acme Feedback',
        customLinks: [...original.customLinks, { label: 'Blog', url: 'https://example.com' }],
      }),
    ).toEqual({
      siteName: 'Acme Feedback',
      customLinks: [
        { label: 'Docs', url: 'https://example.com/docs' },
        { label: 'Blog', url: 'https://example.com' },
      ],
    })
  })

  it('reads and writes header links as Label|URL lines', () => {
    expect(
      parseCustomLinks(' Docs | https://x.y/a|b \n\nbroken line\n|https://x.y\nBlog|'),
    ).toEqual([{ label: 'Docs', url: 'https://x.y/a|b' }])
    expect(formatCustomLinks(settings.customLinks)).toBe('Docs|https://example.com/docs')
  })
})
