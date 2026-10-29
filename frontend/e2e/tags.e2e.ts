import { expect, test } from '@playwright/test'
import { ADMIN_STATE, acceptDialogs, unique } from './helpers'

test.use({ storageState: ADMIN_STATE })

test('an admin creates a tag, tags a post and the board filters by it', async ({
  page,
  request,
}) => {
  acceptDialogs(page)
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const title = unique('E2E tagged')
  const created = await request.post('/api/app/v1/boards/feature-requests/posts', {
    data: { title, formFillMs: 5000 },
    headers,
  })
  expect(created.ok()).toBeTruthy()
  const slug = (await created.json()).slug as string
  const tagName = unique('Mobile')

  await page.goto('/site_settings/tags')
  await page
    .getByRole('button', { name: /new|add/i })
    .first()
    .click()
  await page.getByLabel('Name').fill(tagName)
  await page
    .getByRole('button', { name: /create|save/i })
    .first()
    .click()
  await expect(page.getByText(tagName)).toBeVisible()

  await page.goto(`/posts/${slug}`)
  await page.getByRole('group', { name: 'Tags' }).getByRole('button', { name: tagName }).click()
  await expect(page.getByRole('listitem').filter({ hasText: tagName }).first()).toBeVisible()

  await page.goto('/boards/feature-requests')
  await page
    .getByRole('group', { name: 'Filter by tag' })
    .getByRole('button', { name: tagName })
    .click()
  await expect(page).toHaveURL(/tag=\d+/)
  await expect(page.getByRole('link', { name: title })).toBeVisible()
  await expect(
    page.getByRole('listitem').filter({ hasText: 'There are multiple boards' }),
  ).toHaveCount(0)

  // Clean up
  expect((await request.delete(`/api/app/v1/posts/${slug}`, { headers })).ok()).toBeTruthy()
  const tags = await (await request.get('/api/app/v1/tags')).json()
  for (const tag of tags.filter((t: { name: string }) => t.name === tagName)) {
    await request.delete(`/api/app/v1/tags/${tag.id}`, { headers })
  }
})
