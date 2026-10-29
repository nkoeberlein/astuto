import { describe, expect, it } from 'vitest'
import { embedCode } from './embed'

describe('embedCode', () => {
  const all = { showBoardFilter: true, showStatusFilter: true, boardIds: [], statusIds: [] }

  it('links the embedded roadmap without parameters by default', () => {
    expect(embedCode('https://feedback.example', all)).toContain(
      'src="https://feedback.example/next/embedded_roadmap"',
    )
  })

  it('adds the legacy parameters for scope and hidden filters', () => {
    const code = embedCode('https://feedback.example', {
      showBoardFilter: false,
      showStatusFilter: true,
      boardIds: [1, 2],
      statusIds: [],
    })
    expect(code).toContain('?show_boards=1%2C2&amp;show_board_filter=false"')
  })
})
