import { expect, test } from '@playwright/test'
import { ADMIN_STATE, unique } from './helpers'

test.use({ storageState: ADMIN_STATE })

test('new accounts wait until an admin approves them', async ({ page, request, browser }) => {
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const setApproval = (on: boolean) =>
    request.patch('/api/app/v1/site_settings/general', {
      data: { requireUserApproval: on },
      headers,
    })
  expect((await setApproval(true)).ok()).toBeTruthy()
  const name = unique('Pending Person')
  const email = `${name.replace(/\W+/g, '-').toLowerCase()}@example.com`

  try {
    const visitor = await browser.newContext({ storageState: { cookies: [], origins: [] } })
    const signup = await visitor.newPage()
    await signup.goto('/register')
    await signup.getByLabel('Full name').fill(name)
    await signup.getByLabel('Email').fill(email)
    await signup.getByLabel('Password', { exact: true }).fill('password123')
    await signup.getByLabel('Password confirmation').fill('password123')
    await signup.getByRole('button', { name: 'Sign up' }).click()
    await expect(signup.getByText(/administrator (also )?checks new accounts/)).toBeVisible()
    await visitor.close()

    await page.goto('/moderation/users?status=pending_approval')
    const row = page.getByRole('listitem').filter({ hasText: name })
    await expect(row.getByText('Waiting for approval')).toBeVisible()
    await row.getByRole('button', { name: 'Approve' }).click()
    await expect(row.getByText('Waiting for approval')).toHaveCount(0)
  } finally {
    await setApproval(false)
  }
})
