import { createHmac } from 'node:crypto'
import { expect, test } from '@playwright/test'
import { ADMIN_STATE } from './helpers'

test.use({ storageState: ADMIN_STATE })

// What the customer's server does (docs/widget.md)
function visitorToken(claims: Record<string, unknown>, secret: string) {
  const encode = (part: unknown) => Buffer.from(JSON.stringify(part)).toString('base64url')
  const unsigned = `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(claims)}`
  return `${unsigned}.${createHmac('sha256', secret).update(unsigned).digest('base64url')}`
}

test('the widget on another site signs the visitor in without cookies', async ({
  page,
  request,
  baseURL,
}) => {
  const session = await (await request.get('/api/app/v1/session')).json()
  const headers = { 'X-CSRF-Token': session.csrfToken as string }
  const saved = await request.patch('/api/app/v1/site_settings/widget', {
    data: { enabled: true, allowedOrigins: '' },
    headers,
  })
  expect(saved.ok()).toBeTruthy()
  const { secret } = await saved.json()
  const token = visitorToken(
    {
      email: 'e2e-widget@example.com',
      name: 'Wendy Widget',
      id: 'e2e-1',
      exp: Math.floor(Date.now() / 1000) + 600,
    },
    secret,
  )

  try {
    // A blank page stands in for the customer's site: another origin, no Astuto cookies
    await page.context().clearCookies()
    await page.setContent(
      `<h1>Customer app</h1><script src="${baseURL}/widget.js" data-token="${token}"></script>`,
    )
    await page.getByRole('button', { name: 'Feedback' }).click()
    const widget = page.frameLocator('iframe[title="Feedback"]')
    await expect(widget.getByText('Signed in as Wendy Widget')).toBeVisible()
    await expect(widget.getByRole('button', { name: 'Submit feedback' })).toBeVisible()

    await widget.getByRole('button', { name: 'Close' }).click()
    await expect(page.getByRole('dialog')).toBeHidden()
  } finally {
    const admin = await page.context().browser()?.newContext({ storageState: ADMIN_STATE, baseURL })
    const adminSession = await (await admin?.request.get('/api/app/v1/session'))?.json()
    await admin?.request.patch('/api/app/v1/site_settings/widget', {
      data: { enabled: false },
      headers: { 'X-CSRF-Token': adminSession.csrfToken },
    })
    await admin?.close()
  }
})
