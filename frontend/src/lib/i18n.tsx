import { createContext, type ReactNode, use, useMemo } from 'react'
import type { Translations } from '@/api/client'

type Vars = Record<string, string | number>
export type TFunction = (key: string, vars?: Vars) => string

// Looks up a dotted key in Rails-style translations: %{name} interpolation,
// one/other pluralization via `count`. Missing keys return the key itself.
export function translate(translations: Translations, key: string, vars?: Vars): string {
  let node: string | Translations | undefined = translations
  for (const part of key.split('.')) {
    node = typeof node === 'object' ? node[part] : undefined
  }

  if (typeof node === 'object' && vars?.count !== undefined) {
    node = Number(vars.count) === 1 ? (node.one ?? node.other) : node.other
  }
  if (typeof node !== 'string') return key

  return node.replace(/%\{(\w+)\}/g, (match, name: string) =>
    vars?.[name] !== undefined ? String(vars[name]) : match,
  )
}

type I18n = { locale: string; t: TFunction }

const I18nContext = createContext<I18n | null>(null)

export function I18nProvider(props: {
  locale: string
  translations: Translations
  children: ReactNode
}) {
  const { locale, translations, children } = props
  const value = useMemo<I18n>(
    () => ({ locale, t: (key, vars) => translate(translations, key, vars) }),
    [locale, translations],
  )
  return <I18nContext value={value}>{children}</I18nContext>
}

export function useI18n(): I18n {
  const i18n = use(I18nContext)
  if (!i18n) throw new Error('useI18n must be used inside <I18nProvider>')
  return i18n
}
