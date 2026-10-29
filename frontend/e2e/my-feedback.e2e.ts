import { expect, test } from '@playwright/test'
import { ADMIN_STATE, unique } from './helpers'

test.use({ storageState: ADMIN_STATE })

test('"My feedback" lists own, voted and followed posts', async ({ page, request }) => {
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const title = unique('E2E mine')
  const created = await request.post('/api/app/v1/boards/feature-requests/posts', {
    data: { title, formFillMs: 5000 },
    headers,
  })
  expect(created.ok()).toBeTruthy()
  const slug = (await created.json()).slug as string

  await page.goto('/')
  await page.getByRole('link', { name: 'My feedback' }).click()
  await expect(page.getByRole('heading', { name: 'My feedback' })).toBeVisible()
  const ownItem = page.getByRole('listitem').filter({ hasText: title })
  await expect(ownItem).toBeVisible()
  await expect(ownItem).toContainText('Feature Requests')

  // The author follows their own post
  await page.getByRole('link', { name: /^Following/ }).click()
  await expect(page).toHaveURL(/filter=followed/)
  await expect(page.getByRole('listitem').filter({ hasText: title })).toBeVisible()

  await page.getByRole('link', { name: /^Voted/ }).click()
  await expect(page.getByRole('listitem').filter({ hasText: title })).toHaveCount(0)
  expect((await request.post(`/api/app/v1/posts/${slug}/vote`, { headers })).ok()).toBeTruthy()
  await page.reload()
  await expect(page.getByRole('listitem').filter({ hasText: title })).toBeVisible()

  expect((await request.delete(`/api/app/v1/posts/${slug}`, { headers })).ok()).toBeTruthy()
})
