import { useSuspenseInfiniteQuery } from '@tanstack/react-query'
import { Ban, Check, Download, LockOpen, Trash2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import type { ModerationUser, UserRole, UserStatus } from '@/api/client'
import {
  type UpdateModerationUser,
  useDeleteModerationUser,
  useUpdateModerationUser,
} from '@/api/mutations'
import { moderationUsersQuery, type UserFilters } from '@/api/queries'
import { FormError } from '@/components/FormError'
import { UserAvatar } from '@/components/UserAvatar'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useI18n } from '@/lib/i18n'
import { cn } from '@/lib/utils'
import { ModerationNav } from './ModerationNav'
import {
  ASSIGNABLE_ROLES,
  type AssignableRole,
  confirmationKey,
  USER_ROLES,
  USER_STATUSES,
} from './users'

const ALL = 'all'

type Props = {
  filters: UserFilters
  onFiltersChange: (changes: Partial<UserFilters>) => void
}

// User management (legacy: /moderation/users): search, block and unblock, change roles (admins)
export function UsersModerationPage({ filters, onFiltersChange }: Props) {
  const { t } = useI18n()
  const users = useSuspenseInfiniteQuery(moderationUsersQuery(filters))
  const update = useUpdateModerationUser()

  const items = users.data.pages.flatMap((page) => page.users)
  const counts = users.data.pages[0]?.counts

  const change = (user: ModerationUser, changes: UpdateModerationUser) => {
    const key = confirmationKey(user, changes)
    if (key && !window.confirm(t(key, { name: user.fullName }))) return
    update.mutate({ id: user.id, ...changes })
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <ModerationNav />

      <UserFilterBar filters={filters} onChange={onFiltersChange} />

      {counts && (
        <p className="text-sm text-muted-foreground">
          {counts.total} {t('activerecord.models.user', { count: counts.total })} ({counts.active}{' '}
          {t('moderation.users.status_active')}, {counts.blocked}{' '}
          {t('moderation.users.status_blocked')}, {counts.deleted}{' '}
          {t('moderation.users.status_deleted')}
          {counts.pendingApproval > 0 && (
            <>
              , {counts.pendingApproval} {t('moderation.users.status_pending_approval')}
            </>
          )}
          )
        </p>
      )}

      <FormError error={update.error} />

      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed p-8 text-center text-muted-foreground">
          {t('moderation.users.empty')}
        </p>
      ) : (
        <ul className="divide-y rounded-xl border bg-card shadow-2xs">
          {items.map((user) => (
            <UserRow
              key={user.id}
              user={user}
              busy={update.isPending && update.variables?.id === user.id}
              onChange={(changes) => change(user, changes)}
            />
          ))}
        </ul>
      )}

      {users.hasNextPage && (
        <div className="flex justify-center">
          <Button
            variant="outline"
            onClick={() => users.fetchNextPage()}
            disabled={users.isFetchingNextPage}
          >
            {t('board.posts_list.load_more')}
          </Button>
        </div>
      )}
    </div>
  )
}

function UserFilterBar(props: {
  filters: UserFilters
  onChange: (changes: Partial<UserFilters>) => void
}) {
  const { t } = useI18n()
  const { filters, onChange } = props
  const [search, setSearch] = useState(filters.search)

  // Debounce typing before updating the URL
  useEffect(() => {
    if (search.trim() === filters.search) return
    const timeout = setTimeout(() => onChange({ search: search.trim() }), 300)
    return () => clearTimeout(timeout)
  }, [search, filters.search, onChange])

  return (
    <div className="flex flex-col gap-2 sm:flex-row">
      <Input
        type="search"
        value={search}
        onChange={(event) => setSearch(event.target.value)}
        placeholder={t('moderation.users.search_placeholder')}
        aria-label={t('moderation.users.search_placeholder')}
      />
      <Select
        value={filters.status ?? ALL}
        onValueChange={(value) =>
          onChange({ status: value === ALL ? undefined : (value as UserStatus) })
        }
      >
        <SelectTrigger
          className="w-full sm:w-44"
          aria-label={t('moderation.users.filter_all_statuses')}
        >
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>{t('moderation.users.filter_all_statuses')}</SelectItem>
          {USER_STATUSES.map((status) => (
            <SelectItem key={status} value={status}>
              {t(`moderation.users.status_${status}`)}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <Select
        value={filters.role ?? ALL}
        onValueChange={(value) =>
          onChange({ role: value === ALL ? undefined : (value as UserRole) })
        }
      >
        <SelectTrigger
          className="w-full sm:w-44"
          aria-label={t('moderation.users.filter_all_roles')}
        >
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>{t('moderation.users.filter_all_roles')}</SelectItem>
          {USER_ROLES.map((role) => (
            <SelectItem key={role} value={role}>
              {t(`moderation.users.role_${role}`)}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  )
}

function UserRow(props: {
  user: ModerationUser
  busy: boolean
  onChange: (changes: UpdateModerationUser) => void
}) {
  const { t } = useI18n()
  const { user } = props
  const blocked = user.status === 'blocked'
  const waiting = user.status === 'pending_approval'

  return (
    <li className="flex flex-col gap-3 p-4 sm:flex-row sm:items-center">
      <div className="flex min-w-0 flex-1 items-center gap-3">
        <UserAvatar name={user.fullName} url={user.avatarUrl} className="size-9" />
        <div className="min-w-0">
          <p className="flex flex-wrap items-center gap-2 font-medium">
            <span className="truncate">{user.fullName}</span>
            {user.status !== 'active' && (
              <span
                className={cn(
                  'rounded-full px-2 py-0.5 text-xs font-normal',
                  blocked ? 'bg-destructive/10 text-destructive' : 'bg-muted text-muted-foreground',
                )}
              >
                {t(`moderation.users.status_${user.status}`)}
              </span>
            )}
          </p>
          <p className="truncate text-sm text-muted-foreground">{user.email}</p>
        </div>
      </div>

      <div className="flex shrink-0 items-center justify-between gap-2 sm:justify-end">
        {user.canChangeRole ? (
          <Select
            value={user.role}
            disabled={props.busy}
            onValueChange={(role) => props.onChange({ role: role as AssignableRole })}
          >
            <SelectTrigger
              className="w-40"
              aria-label={`${user.fullName}: ${t('activerecord.attributes.user.role')}`}
            >
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {ASSIGNABLE_ROLES.map((role) => (
                <SelectItem key={role} value={role}>
                  {t(`moderation.users.role_${role}`)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        ) : (
          <span className="text-sm text-muted-foreground sm:w-40 sm:text-end">
            {t(`moderation.users.role_${user.role}`)}
          </span>
        )}
        {user.canChangeStatus && waiting && (
          <Button
            type="button"
            size="sm"
            disabled={props.busy}
            onClick={() => props.onChange({ status: 'active' })}
          >
            <Check className="size-4" aria-hidden />
            {t('moderation.users.approve')}
          </Button>
        )}
        {user.canChangeStatus && (
          <Button
            type="button"
            size="sm"
            variant={blocked ? 'outline' : 'ghost'}
            disabled={props.busy}
            onClick={() => props.onChange({ status: blocked ? 'active' : 'blocked' })}
            className={cn(!blocked && 'text-destructive hover:text-destructive')}
          >
            {blocked ? (
              <LockOpen className="size-4" aria-hidden />
            ) : (
              <Ban className="size-4" aria-hidden />
            )}
            {blocked ? t('moderation.users.unblock') : t('moderation.users.block')}
          </Button>
        )}
        {user.canExport && (
          <Button asChild size="icon" variant="ghost">
            <a
              href={`/api/app/v1/moderation/users/${user.id}/export`}
              download
              aria-label={`${user.fullName}: ${t('moderation.users.export_data')}`}
              title={t('moderation.users.export_data')}
            >
              <Download className="size-4" aria-hidden />
            </a>
          </Button>
        )}
        {user.canDelete && <DeleteUserButton user={user} />}
      </div>
    </li>
  )
}

function DeleteUserButton({ user }: { user: ModerationUser }) {
  const { t } = useI18n()
  const remove = useDeleteModerationUser()
  return (
    <Button
      type="button"
      size="icon"
      variant="ghost"
      className="text-destructive hover:text-destructive"
      disabled={remove.isPending}
      aria-label={`${user.fullName}: ${t('moderation.users.delete_account')}`}
      title={t('moderation.users.delete_account')}
      onClick={() => {
        if (
          window.confirm(t('moderation.users.delete_account_confirmation', { name: user.fullName }))
        )
          remove.mutate(user.id)
      }}
    >
      <Trash2 className="size-4" aria-hidden />
    </Button>
  )
}
