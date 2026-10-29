import { useSuspenseQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { ArrowLeftRight } from 'lucide-react'
import { useState } from 'react'
import type { PostStatus } from '@/api/client'
import { usePostStatusMutations } from '@/api/mutations'
import { boardsQuery, postStatusesQuery, sessionQuery } from '@/api/queries'
import { CopyButton } from '@/components/CopyButton'
import { FilterChip } from '@/components/FilterChip'
import { FormError } from '@/components/FormError'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { useI18n } from '@/lib/i18n'
import { toggleId } from '@/lib/search-params'
import { type EmbedOptions, embedCode } from './embed'
import { CheckboxField, SettingsSection } from './fields'

// Site settings › Roadmap (legacy: /site_settings/roadmap): statuses in the roadmap, embed code
export function RoadmapSettingsPage() {
  const { t } = useI18n()
  const { data: session } = useSuspenseQuery(sessionQuery)
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const { update } = usePostStatusMutations()

  const inRoadmap = statuses.filter((status) => status.showInRoadmap)
  const notInRoadmap = statuses.filter((status) => !status.showInRoadmap)
  const toggle = (status: PostStatus) =>
    update.mutate({ id: status.id, showInRoadmap: !status.showInRoadmap })

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-semibold tracking-tight">{t('site_settings.roadmap.title')}</h2>
      {!session.tenant.settings.roadmapEnabled && (
        <p className="rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
          {t('site_settings.general.roadmap_enabled_help')}{' '}
          <Link to="/site_settings/general" className="text-primary underline">
            {t('site_settings.menu.general')}
          </Link>
        </p>
      )}
      <p className="text-sm text-muted-foreground">{t('site_settings.roadmap.help_buttons')}</p>
      <FormError error={update.error} />

      <div className="grid gap-4 sm:grid-cols-2">
        <StatusColumn
          title={t('site_settings.roadmap.title')}
          statuses={inRoadmap}
          busyId={update.isPending ? update.variables?.id : undefined}
          onToggle={toggle}
        />
        <StatusColumn
          title={t('site_settings.roadmap.title2')}
          statuses={notInRoadmap}
          busyId={update.isPending ? update.variables?.id : undefined}
          onToggle={toggle}
        />
      </div>

      <EmbedSection />
    </div>
  )
}

function StatusColumn(props: {
  title: string
  statuses: PostStatus[]
  busyId: number | undefined
  onToggle: (status: PostStatus) => void
}) {
  const { t } = useI18n()
  return (
    <SettingsSection title={props.title}>
      {props.statuses.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t('site_settings.roadmap.empty')}</p>
      ) : (
        <ul className="space-y-2">
          {props.statuses.map((status) => (
            <li key={status.id} className="flex items-center gap-2">
              <span
                className="size-3 shrink-0 rounded-full"
                style={{ backgroundColor: status.color }}
                aria-hidden
              />
              <span className="min-w-0 flex-1 truncate text-sm font-medium">{status.name}</span>
              <Button
                type="button"
                size="icon"
                variant="ghost"
                className="size-7 text-muted-foreground"
                disabled={props.busyId === status.id}
                onClick={() => props.onToggle(status)}
                aria-label={`${status.name}: ${t('site_settings.roadmap.title2')} / ${t('site_settings.roadmap.title')}`}
                title={`${status.name}: ${t('site_settings.roadmap.title2')} / ${t('site_settings.roadmap.title')}`}
              >
                <ArrowLeftRight className="size-4" aria-hidden />
              </Button>
            </li>
          ))}
        </ul>
      )}
    </SettingsSection>
  )
}

function EmbedSection() {
  const { t } = useI18n()
  const { data: boards } = useSuspenseQuery(boardsQuery)
  const { data: statuses } = useSuspenseQuery(postStatusesQuery)
  const [options, setOptions] = useState<EmbedOptions>({
    showBoardFilter: true,
    showStatusFilter: false,
    boardIds: [],
    statusIds: [],
  })
  const code = embedCode(window.location.origin, options)
  const roadmapStatuses = statuses.filter((status) => status.showInRoadmap)

  return (
    <SettingsSection title={t('site_settings.roadmap.title_embed')}>
      <CheckboxField
        label={t('site_settings.roadmap.show_board_filter')}
        checked={options.showBoardFilter}
        onChange={(showBoardFilter) => setOptions({ ...options, showBoardFilter })}
      />
      <CheckboxField
        label={t('site_settings.roadmap.show_post_status_filter')}
        checked={options.showStatusFilter}
        onChange={(showStatusFilter) => setOptions({ ...options, showStatusFilter })}
      />
      <p className="text-sm text-muted-foreground">{t('site_settings.roadmap.embed_scope_help')}</p>
      {boards.length > 1 && (
        <fieldset className="flex flex-wrap gap-2">
          <legend className="mb-2 text-sm font-medium">{t('roadmap.filter_by_board')}</legend>
          {boards.map((board) => (
            <FilterChip
              key={board.id}
              active={options.boardIds.includes(board.id)}
              onClick={() =>
                setOptions({ ...options, boardIds: toggleId(options.boardIds, board.id) })
              }
            >
              {board.name}
            </FilterChip>
          ))}
        </fieldset>
      )}
      {roadmapStatuses.length > 1 && (
        <fieldset className="flex flex-wrap gap-2">
          <legend className="mb-2 text-sm font-medium">{t('board.filter_box.title')}</legend>
          {roadmapStatuses.map((status) => (
            <FilterChip
              key={status.id}
              color={status.color}
              active={options.statusIds.includes(status.id)}
              onClick={() =>
                setOptions({ ...options, statusIds: toggleId(options.statusIds, status.id) })
              }
            >
              {status.name}
            </FilterChip>
          ))}
        </fieldset>
      )}
      <Textarea
        readOnly
        rows={3}
        value={code}
        aria-label={t('site_settings.roadmap.title_embed')}
        className="font-mono text-xs"
        onFocus={(event) => event.target.select()}
      />
      <div className="flex flex-wrap items-center gap-3">
        <CopyButton text={code} />
        <p className="text-sm text-muted-foreground">{t('site_settings.roadmap.embed_help')}</p>
      </div>
    </SettingsSection>
  )
}
