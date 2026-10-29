import type { CustomLink, GeneralSettings, UpdateGeneralSettings } from '@/api/client'

// Language names in their own language (same list as the legacy settings page)
export const LOCALE_NAMES: Record<string, string> = {
  en: '🇬🇧 English',
  it: '🇮🇹 Italiano',
  de: '🇩🇪 Deutsch',
  fr: '🇫🇷 Français',
  es: '🇪🇸 Español',
  pt: '🇵🇹 Português',
  'zh-CN': '🇨🇳 中文',
  ru: '🇷🇺 Русский',
  vi: '🇻🇳 Tiếng Việt',
  tr: '🇹🇷 Türkçe',
  cs: '🇨🇿 Čeština',
  pl: '🇵🇱 Polski',
  el: '🇬🇷 Ελληνικά',
  hi: '🇮🇳 हिन्दी',
  nl: '🇳🇱 Nederlands',
  sr: '🇷🇸 Српски',
  sv: '🇸🇪 Svenska',
}

// The editable part of the settings; the rest (multiTenancy, availableLocales) is read-only
export type GeneralDraft = Required<UpdateGeneralSettings>

export function draftFromSettings(settings: GeneralSettings): GeneralDraft {
  const { multiTenancy: _multiTenancy, availableLocales: _availableLocales, ...draft } = settings
  return draft
}

// Only the fields that differ, so a save never overwrites what someone else changed meanwhile
export function changedFields(original: GeneralDraft, draft: GeneralDraft): UpdateGeneralSettings {
  const changes: Record<string, unknown> = {}
  for (const key of Object.keys(draft) as (keyof GeneralDraft)[]) {
    if (JSON.stringify(draft[key]) !== JSON.stringify(original[key])) changes[key] = draft[key]
  }
  return changes as UpdateGeneralSettings
}

// Header links as text, one per line: "Label|URL" (the legacy format)
export function formatCustomLinks(links: CustomLink[]): string {
  return links.map((link) => `${link.label}|${link.url}`).join('\n')
}

// Lines without a "|" or with an empty part are skipped; the server checks the URLs
export function parseCustomLinks(text: string): CustomLink[] {
  return text.split('\n').flatMap((line) => {
    const index = line.indexOf('|')
    if (index < 0) return []
    const label = line.slice(0, index).trim()
    const url = line.slice(index + 1).trim()
    return label && url ? [{ label, url }] : []
  })
}
