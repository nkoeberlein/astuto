import { expect, test } from '@playwright/test'
import { ADMIN_STATE, acceptDialogs, unique } from './helpers'

test.use({ storageState: ADMIN_STATE })

test('a moderator publishes a changelog entry that links a post', async ({ page, request }) => {
  acceptDialogs(page)
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const postTitle = unique('E2E shipped')
  const created = await request.post('/api/app/v1/boards/feature-requests/posts', {
    data: { title: postTitle, formFillMs: 5000 },
    headers,
  })
  expect(created.ok()).toBeTruthy()
  const slug = (await created.json()).slug as string
  const entryTitle = unique('E2E release')

  await page.goto('/')
  await page.getByRole('link', { name: 'Changelog' }).first().click()
  await page.getByRole('button', { name: 'New entry' }).click()
  await page.getByLabel('Title').fill(entryTitle)
  await page.getByLabel('Find posts').fill(postTitle)
  await page
    .getByRole('listitem')
    .filter({ hasText: postTitle })
    .getByRole('button', { name: 'Add' })
    .click()
  await page.getByLabel('Text (Markdown)').fill('Now **shipped**.')
  await page.getByRole('button', { name: 'Publish' }).click()

  const entry = page.getByRole('article', { name: entryTitle })
  await expect(entry).toBeVisible()
  await expect(entry.getByRole('link', { name: postTitle })).toBeVisible()
  await expect(entry.locator('strong')).toHaveText('shipped')

  // The post page links back to the entry
  await entry.getByRole('link', { name: postTitle }).click()
  await expect(page).toHaveURL(new RegExp(`/posts/${slug}$`))
  await page.getByRole('link', { name: entryTitle }).click()
  await expect(page).toHaveURL(/\/changelog#entry-\d+$/)

  // Clean up
  await page
    .getByRole('article', { name: entryTitle })
    .getByRole('button', { name: 'Delete' })
    .click()
  await expect(page.getByRole('article', { name: entryTitle })).toHaveCount(0)
  expect((await request.delete(`/api/app/v1/posts/${slug}`, { headers })).ok()).toBeTruthy()
})
