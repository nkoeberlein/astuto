import { useSuspenseQuery } from '@tanstack/react-query'
import { Send } from 'lucide-react'
import { useState } from 'react'
import { useInvitationMutations } from '@/api/mutations'
import { invitationsQuery, sessionQuery } from '@/api/queries'
import { FilterChip } from '@/components/FilterChip'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { formatRelativeTime } from '@/lib/format'
import { useI18n } from '@/lib/i18n'
import { SettingsSection, TextField } from './fields'
import {
  filterInvitations,
  type InvitationFilter,
  LINK_PLACEHOLDER,
  MAX_INVITATIONS,
  parseEmailList,
} from './invitations'

// Site settings › Invitations (legacy: /site_settings/invitations)
export function InvitationsSettingsPage() {
  const { t } = useI18n()
  return (
    <div className="space-y-6">
      <h2 className="text-xl font-semibold tracking-tight">
        {t('site_settings.menu.invitations')}
      </h2>
      <NewInvitations />
      <PastInvitations />
    </div>
  )
}

function NewInvitations() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { send, test } = useInvitationMutations()
  const siteName = session.tenant.siteName
  const [to, setTo] = useState('')
  const [subject, setSubject] = useState(
    t('site_settings.invitations.subject_default', { name: siteName }),
  )
  const [body, setBody] = useState(t('site_settings.invitations.body_default', { name: siteName }))

  const emails = parseEmailList(to)
  const problem =
    emails.length > MAX_INVITATIONS
      ? t('site_settings.invitations.too_many_emails', { count: MAX_INVITATIONS })
      : !body.includes(LINK_PLACEHOLDER)
        ? t('site_settings.invitations.invitation_link_not_found')
        : null

  return (
    <SettingsSection title={t('site_settings.invitations.new_invitations_title')}>
      <form
        className="space-y-4"
        onSubmit={(event) => {
          event.preventDefault()
          test.reset()
          send.mutate(
            { to: emails, subject, body },
            { onSuccess: (result) => result.sent > 0 && setTo('') },
          )
        }}
      >
        <TextField
          label={t('site_settings.invitations.to')}
          value={to}
          onChange={setTo}
          placeholder="ada@example.com, grace@example.com"
          help={t('site_settings.invitations.to_help')}
        />
        <TextField
          label={t('site_settings.invitations.subject')}
          value={subject}
          onChange={setSubject}
        />
        <div className="space-y-1.5">
          <Label htmlFor="invitation-body">{t('site_settings.invitations.body')}</Label>
          <Textarea
            id="invitation-body"
            rows={10}
            value={body}
            onChange={(event) => setBody(event.target.value)}
          />
        </div>
        {problem && <p className="text-sm text-destructive">{problem}</p>}

        <div className="flex flex-wrap items-center gap-3">
          <Button
            type="submit"
            disabled={emails.length === 0 || problem !== null || send.isPending}
          >
            <Send className="size-4" aria-hidden />
            {t('site_settings.invitations.send', { count: emails.length })}
          </Button>
          <Button
            type="button"
            variant="outline"
            disabled={problem !== null || test.isPending}
            onClick={() => {
              send.reset()
              test.mutate({ subject, body })
            }}
            title={t('site_settings.invitations.test_invitation_help', {
              email: session.user?.email ?? '',
            })}
          >
            {t('site_settings.invitations.test_invitation_button')}
          </Button>
        </div>
        <p className="text-sm text-muted-foreground" aria-live="polite">
          {send.data &&
            `${t('site_settings.invitations.submit_success')} (${send.data.sent})${
              send.data.skipped.length
                ? ` · ${t('site_settings.invitations.skipped', { emails: send.data.skipped.join(', ') })}`
                : ''
            }`}
          {test.data &&
            t('site_settings.invitations.test_invitation_success', { email: test.data.sentTo })}
        </p>
        <FormError error={send.error ?? test.error} />
      </form>
    </SettingsSection>
  )
}

function PastInvitations() {
  const { t, locale } = useI18n()
  const { data: invitations } = useSuspenseQuery(invitationsQuery)
  const [filter, setFilter] = useState<InvitationFilter>('all')
  const shown = filterInvitations(invitations, filter)

  return (
    <SettingsSection title={t('site_settings.invitations.past_invitations_title')}>
      <div className="flex flex-wrap gap-2">
        {(['all', 'pending', 'accepted', 'expired'] as const).map((option) => (
          <FilterChip key={option} active={filter === option} onClick={() => setFilter(option)}>
            {t(`site_settings.invitations.${option}`)}
          </FilterChip>
        ))}
      </div>
      {shown.length === 0 ? (
        <p className="text-sm text-muted-foreground">—</p>
      ) : (
        <ul className="divide-y">
          {shown.map((invitation) => (
            <li
              key={invitation.id}
              className="flex flex-wrap items-center justify-between gap-2 py-2 text-sm"
            >
              <span className="truncate font-medium">{invitation.email}</span>
              <span className="text-muted-foreground">
                {invitation.status === 'accepted' && invitation.acceptedAt
                  ? t('site_settings.invitations.accepted_at', {
                      when: formatRelativeTime(invitation.acceptedAt, locale),
                    })
                  : invitation.status === 'expired'
                    ? t('site_settings.invitations.expired')
                    : t('site_settings.invitations.sent_at', {
                        when: formatRelativeTime(invitation.sentAt, locale),
                      })}
              </span>
            </li>
          ))}
        </ul>
      )}
    </SettingsSection>
  )
}
