import { infiniteQueryOptions, queryOptions } from '@tanstack/react-query'
import {
  api,
  setCsrfToken,
  type Translations,
  type UserRole,
  type UserStatus,
  unwrap,
} from './client'

export const SORT_OPTIONS = ['trending', 'newest', 'most_voted', 'oldest'] as const
export type SortBy = (typeof SORT_OPTIONS)[number]

export type PostFilters = {
  search: string
  sortBy: SortBy
  statusIds: number[]
}

export const sessionQuery = queryOptions({
  queryKey: ['session'],
  queryFn: async () => {
    const session = await unwrap(api.GET('/api/app/v1/session'))
    setCsrfToken(session.csrfToken)
    return session
  },
  staleTime: 5 * 60_000,
})

export const translationsQuery = (locale: string) =>
  queryOptions({
    queryKey: ['translations', locale],
    queryFn: async () =>
      (await unwrap(
        api.GET('/api/app/v1/translations/{locale}', { params: { path: { locale } } }),
      )) as Translations,
    staleTime: Number.POSITIVE_INFINITY,
  })

export const boardsQuery = queryOptions({
  queryKey: ['boards'],
  queryFn: () => unwrap(api.GET('/api/app/v1/boards')),
})

export const postStatusesQuery = queryOptions({
  queryKey: ['postStatuses'],
  queryFn: () => unwrap(api.GET('/api/app/v1/post_statuses')),
  staleTime: 5 * 60_000,
})

export const boardStatusesQuery = (boardSlug: string, hideUnused: boolean) =>
  queryOptions({
    queryKey: hideUnused ? ['postStatuses', 'board', boardSlug] : ['postStatuses'],
    queryFn: () =>
      unwrap(
        api.GET(
          '/api/app/v1/post_statuses',
          hideUnused ? { params: { query: { board_id: boardSlug } } } : {},
        ),
      ),
    staleTime: 60_000,
  })

export const boardPostsQuery = (boardSlug: string, filters: PostFilters) =>
  infiniteQueryOptions({
    queryKey: ['boards', boardSlug, 'posts', filters],
    queryFn: ({ pageParam }) =>
      unwrap(
        api.GET('/api/app/v1/boards/{board_id}/posts', {
          params: {
            path: { board_id: boardSlug },
            query: {
              page: pageParam,
              sort_by: filters.sortBy,
              search: filters.search || undefined,
              'post_status_ids[]': filters.statusIds.length ? filters.statusIds : undefined,
            },
          },
        }),
      ),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => (lastPage.hasMore ? lastPage.page + 1 : undefined),
  })

export const ROADMAP_SORT_OPTIONS = ['most_voted', 'recently_updated'] as const
export type RoadmapSortBy = (typeof ROADMAP_SORT_OPTIONS)[number]

export const roadmapQuery = (sortBy: RoadmapSortBy) =>
  queryOptions({
    queryKey: ['roadmap', sortBy],
    queryFn: () =>
      unwrap(api.GET('/api/app/v1/roadmap', { params: { query: { sort_by: sortBy } } })),
  })

export const postQuery = (postSlug: string) =>
  queryOptions({
    queryKey: ['posts', postSlug],
    queryFn: () =>
      unwrap(api.GET('/api/app/v1/posts/{id}', { params: { path: { id: postSlug } } })),
  })

export const similarPostsQuery = (boardSlug: string, query: string) => {
  const trimmed = query.trim()
  return queryOptions({
    queryKey: ['boards', boardSlug, 'similarPosts', trimmed],
    queryFn: () =>
      unwrap(
        api.GET('/api/app/v1/boards/{board_id}/posts', {
          params: {
            path: { board_id: boardSlug },
            query: {
              page: 1,
              sort_by: 'most_voted',
              search: trimmed,
            },
          },
        }),
      ),
    enabled: trimmed.length >= 3,
    staleTime: 30_000,
  })
}

export const commentsQuery = (postSlug: string) =>
  queryOptions({
    queryKey: ['posts', postSlug, 'comments'],
    queryFn: () =>
      unwrap(
        api.GET('/api/app/v1/posts/{post_id}/comments', {
          params: { path: { post_id: postSlug } },
        }),
      ),
  })

// Feedback queue of moderators: pending and rejected posts
export const moderationPostsQuery = queryOptions({
  queryKey: ['moderation', 'posts'],
  queryFn: () => unwrap(api.GET('/api/app/v1/moderation/posts')),
})

// Empty search and missing role/status mean "all users"
export type UserFilters = { search: string; role?: UserRole; status?: UserStatus }

export const moderationUsersQuery = (filters: UserFilters) =>
  infiniteQueryOptions({
    queryKey: ['moderation', 'users', filters],
    queryFn: ({ pageParam }) =>
      unwrap(
        api.GET('/api/app/v1/moderation/users', {
          params: {
            query: {
              page: pageParam,
              search: filters.search || undefined,
              role: filters.role,
              status: filters.status,
            },
          },
        }),
      ),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => (lastPage.hasMore ? lastPage.page + 1 : undefined),
  })

// Site settings › General (admins)
export const generalSettingsQuery = queryOptions({
  queryKey: ['siteSettings', 'general'],
  queryFn: () => unwrap(api.GET('/api/app/v1/site_settings/general')),
})

// Site settings › Authentication: own and default OAuth providers (admins)
export const oAuthSettingsQuery = queryOptions({
  queryKey: ['siteSettings', 'oAuths'],
  queryFn: () => unwrap(api.GET('/api/app/v1/site_settings/o_auths')),
})
