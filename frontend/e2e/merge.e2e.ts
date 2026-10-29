import { expect, test } from '@playwright/test'
import { ADMIN_STATE, acceptDialogs, unique } from './helpers'

test.use({ storageState: ADMIN_STATE })

test('a moderator merges a duplicate; its link leads to the kept post', async ({
  page,
  request,
}) => {
  acceptDialogs(page)
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const create = async (title: string) => {
    const response = await request.post('/api/app/v1/boards/feature-requests/posts', {
      data: { title, formFillMs: 5000 },
      headers,
    })
    expect(response.ok()).toBeTruthy()
    return (await response.json()).slug as string
  }
  const keptTitle = unique('E2E keep')
  const kept = await create(keptTitle)
  const duplicate = await create(unique('E2E duplicate'))

  await page.goto(`/posts/${duplicate}`)
  await page.getByRole('button', { name: 'Merge into another post' }).click()
  await page.getByLabel('Find the post to keep').fill(keptTitle)
  await page
    .getByRole('listitem')
    .filter({ hasText: keptTitle })
    .getByRole('button', { name: 'Merge here' })
    .click()
  await expect(page).toHaveURL(new RegExp(`/posts/${kept}$`))
  await expect(page.getByText('Merged from:')).toBeVisible()

  // The old link leads to the kept post
  await page.goto(`/posts/${duplicate}`)
  await expect(page).toHaveURL(new RegExp(`/posts/${kept}$`))

  // Clean up: deleting the kept post removes the merged one too
  await page.getByRole('button', { name: 'Delete' }).first().click()
  await expect(page).toHaveURL(/\/boards\/feature-requests/)
})
