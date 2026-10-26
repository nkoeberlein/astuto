import { useLocation } from '@tanstack/react-router'
import { APP_BASEPATH } from '@/lib/project'

// Pages where a "return here after login" target makes no sense
const AUTH_PATHS = ['/login', '/register', '/password/forgot', '/password/reset']

// Return target after sign-in: only a path inside the app, never another host.
// Same rules as SafeUrl.local_path? on the server ("//host" and "/\host" count
// as other hosts in browsers).
export function safeRedirect(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined
  if (!value.startsWith('/') || value.startsWith('//') || /[\\\r\n]/.test(value)) return undefined
  return value
}

// Current page (path + query, without the /next basepath) as the redirect
// search param for links to /login and /register
export function useLoginRedirect(): string | undefined {
  const { pathname, href } = useLocation()
  if (AUTH_PATHS.includes(pathname)) return undefined
  return safeRedirect(href)
}

// OAuth start URL with the page to return to. The server only accepts local
// paths and the OAuth flow leaves the SPA, so the basepath is added here.
export function oauthStartUrl(
  startUrl: string,
  redirect: string | undefined,
  basepath: string = APP_BASEPATH,
) {
  const url = new URL(startUrl, window.location.origin)
  url.searchParams.set('return_to', `${basepath}${redirect ?? '/'}`)
  return url.toString()
}
