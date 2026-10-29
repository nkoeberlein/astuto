import { APP_BASEPATH } from '@/lib/project'

export type EmbedOptions = {
  showBoardFilter: boolean
  showStatusFilter: boolean
  // Empty lists mean all boards or statuses
  boardIds: number[]
  statusIds: number[]
}

// iframe code for the embedded roadmap, with the legacy parameters (only those that differ
// from the defaults)
export function embedCode(origin: string, options: EmbedOptions): string {
  const params = new URLSearchParams()
  if (options.boardIds.length) params.set('show_boards', options.boardIds.join(','))
  if (options.statusIds.length) params.set('show_statuses', options.statusIds.join(','))
  if (!options.showBoardFilter) params.set('show_board_filter', 'false')
  if (!options.showStatusFilter) params.set('show_status_filter', 'false')
  const query = params.toString()
  const src = `${origin}${APP_BASEPATH}/embedded_roadmap${query ? `?${query}` : ''}`
  return `<iframe src="${src.replace(/&/g, '&amp;')}" width="100%" height="600" style="border:0" title="Roadmap" loading="lazy"></iframe>`
}
