import { expect, test } from '@playwright/test'
import { ADMIN_STATE, unique } from './helpers'

test.use({ storageState: ADMIN_STATE })

test('a board for moderators only is hidden from visitors', async ({ page, request, browser }) => {
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const name = unique('E2E internal')
  const created = await request.post('/api/app/v1/boards', {
    data: { name, visibility: 'staff' },
    headers,
  })
  expect(created.ok()).toBeTruthy()
  const board = await created.json()

  try {
    await page.goto(`/boards/${board.slug}`)
    await expect(page.getByText('Only moderators and admins')).toBeVisible()

    const visitor = await browser.newContext({ storageState: { cookies: [], origins: [] } })
    const visitorPage = await visitor.newPage()
    await visitorPage.goto('/')
    await expect(visitorPage.getByRole('navigation', { name: 'Boards' })).toBeVisible()
    await expect(visitorPage.getByRole('link', { name })).toHaveCount(0)
    await visitorPage.goto(`/boards/${board.slug}`)
    await expect(visitorPage.getByRole('heading', { name })).toHaveCount(0)
    await visitor.close()
  } finally {
    await request.delete(`/api/app/v1/boards/${board.id}`, { headers })
  }
})
