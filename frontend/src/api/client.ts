import createClient, { type Middleware } from 'openapi-fetch'
import type { components, paths } from './schema'

export type Schemas = components['schemas']
export type Session = Schemas['Session']
export type OAuthProvider = Schemas['OAuthProvider']
export type Board = Schemas['Board']
export type PostStatus = Schemas['PostStatus']
export type PostListItem = Schemas['PostListItem']
export type PostPage = Schemas['PostPage']
export type MyPost = Schemas['MyPost']
export type ChangelogEntry = Schemas['ChangelogEntry']
export type ChangelogEntryInput = Schemas['ChangelogEntryInput']
export type Post = Schemas['Post']
export type Comment = Schemas['Comment']
export type Author = Schemas['Author']
export type Roadmap = Schemas['Roadmap']
export type RoadmapColumn = Schemas['RoadmapColumn']
export type RoadmapPost = Schemas['RoadmapPost']
export type ModerationPost = Schemas['ModerationPost']
export type ModerationQueue = Schemas['ModerationQueue']
export type ModerationUser = Schemas['ModerationUser']
export type ModerationUserPage = Schemas['ModerationUserPage']
export type UserRole = ModerationUser['role']
export type UserStatus = ModerationUser['status']
export type GeneralSettings = Schemas['GeneralSettings']
export type AuditEvent = Schemas['AuditEvent']
export type SamlSettings = Schemas['SamlSettings']
export type LdapSettings = Schemas['LdapSettings']
export type UpdateLdapSettings = Schemas['UpdateLdapSettings']
export type LdapLoginInput = Schemas['LdapLoginInput']
export type UpdateSamlSettings = Schemas['UpdateSamlSettings']
export type AuditChange = Schemas['AuditChange']
export type UpdateGeneralSettings = Schemas['UpdateGeneralSettings']
export type CustomLink = Schemas['CustomLink']
export type BoardInput = Schemas['BoardInput']
export type PostStatusInput = Schemas['PostStatusInput']
export type OAuthSettings = Schemas['OAuthSettings']
export type OAuthInput = Schemas['OAuthInput']
export type Webhook = Schemas['Webhook']
export type WebhookInput = Schemas['WebhookInput']
export type WebhookHeader = Schemas['WebhookHeader']
export type WebhookDelivery = Schemas['WebhookDelivery']
export type Invitation = Schemas['Invitation']
export type Profile = Schemas['Profile']
export type UpdateProfile = Schemas['UpdateProfile']
export type Translations = { [key: string]: string | Translations }

export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

// Rails checks this header on write requests; the token comes from GET /session
let csrfToken: string | undefined

export function setCsrfToken(token: string) {
  csrfToken = token
}

const headers: Middleware = {
  onRequest({ request }) {
    request.headers.set('Accept', 'application/json')
    if (request.method !== 'GET' && csrfToken) request.headers.set('X-CSRF-Token', csrfToken)
    return request
  },
}

export const api = createClient<paths>({ baseUrl: '', credentials: 'same-origin' })
api.use(headers)

type FetchResult<T> = { data?: T; error?: unknown; response: Response }

// Returns the response data or throws an ApiError with the server's message
export async function unwrap<T>(request: Promise<FetchResult<T>>): Promise<T> {
  const { data, error, response } = await request
  if (error !== undefined || (data === undefined && response.status !== 204)) {
    const message =
      typeof error === 'object' && error !== null && 'error' in error
        ? String(error.error)
        : response.statusText
    throw new ApiError(response.status, message)
  }
  return data as T
}
