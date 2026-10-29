import { expect, test } from '@playwright/test'
import { ADMIN, ADMIN_STATE, acceptDialogs, totp } from './helpers'

test.use({ storageState: ADMIN_STATE })

// Sets up two-factor authentication for the admin, logs in with a code in a fresh browser and
// turns it off again (also when the test fails, so later runs can still log in)
test.describe('two-factor authentication', () => {
  test.afterEach(async ({ request }) => {
    await request.delete('/api/app/v1/profile/two_factor', {
      data: { currentPassword: ADMIN.password },
      headers: { 'X-CSRF-Token': await csrfToken(request) },
    })
  })

  test('set up, log in with a code, turn off', async ({ page, browser }) => {
    acceptDialogs(page)
    await page.goto('/profile')
    const section = page.getByRole('region', { name: 'Two-factor authentication' })
    await section.getByLabel('Current password').fill(ADMIN.password)
    await section.getByRole('button', { name: 'Set up two-factor authentication' }).click()
    await expect(
      section.getByRole('img', { name: 'QR code for the authenticator app' }),
    ).toBeVisible()

    const secret = ((await section.locator('code').textContent()) ?? '').replaceAll(' ', '')
    await section.getByLabel('Code').fill(totp(secret))
    await section.getByRole('button', { name: 'Turn on' }).click()
    const codes = section.getByRole('list', { name: 'Backup codes' }).getByRole('listitem')
    await expect(codes).toHaveCount(10)
    const backupCode = (await codes.first().textContent()) ?? ''
    await section.getByRole('button', { name: 'I have saved the codes' }).click()
    await expect(section.getByText('On. 10 backup codes left.')).toBeVisible()

    // A fresh browser: password, then the code
    const context = await browser.newContext({ storageState: { cookies: [], origins: [] } })
    const other = await context.newPage()
    await other.goto('/login')
    await other.getByLabel('Email').fill(ADMIN.email)
    await other.getByLabel('Password', { exact: true }).fill(ADMIN.password)
    await other.getByRole('button', { name: 'Log in', exact: true }).click()
    await expect(other.getByRole('heading', { name: 'Two-factor authentication' })).toBeVisible()
    await other.getByLabel('Code').fill('000000')
    await other.getByRole('button', { name: 'Verify' }).click()
    await expect(other.getByRole('alert')).toBeVisible()
    await other.getByLabel('Code').fill(backupCode)
    await other.getByRole('button', { name: 'Verify' }).click()
    await other.waitForURL((url) => !url.pathname.endsWith('/login'))
    await expect(other.getByRole('button', { name: /Sign out/ })).toBeVisible()
    await context.close()

    // Off again
    await page.reload()
    await section.getByLabel('Current password').fill(ADMIN.password)
    await section.getByRole('button', { name: 'Turn off two-factor authentication' }).click()
    await expect(
      section.getByRole('button', { name: 'Set up two-factor authentication' }),
    ).toBeVisible()
  })
})

async function csrfToken(request: import('@playwright/test').APIRequestContext) {
  const session = await (await request.get('/api/app/v1/session')).json()
  return session.csrfToken as string
}
