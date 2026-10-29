import type { Page } from '@playwright/test'

// Credentials of an admin of the instance under test (development seeds by default)
export const ADMIN = {
  email: process.env.E2E_ADMIN_EMAIL ?? 'admin@example.com',
  password: process.env.E2E_ADMIN_PASSWORD ?? 'password',
}

// Session of the admin, saved by auth.setup.ts
export const ADMIN_STATE = 'e2e/.auth/admin.json'

// Unique names, so runs against the same database do not collide
export const unique = (prefix: string) => `${prefix} ${Date.now().toString(36)}`

// Logs in on the v2 login page and waits for the redirect to `redirect`
export async function logIn(page: Page, redirect = '/') {
  await page.goto(`/next/login?redirect=${encodeURIComponent(redirect)}`)
  await page.getByLabel('Email').fill(ADMIN.email)
  await page.getByLabel('Password', { exact: true }).fill(ADMIN.password)
  await page.getByRole('button', { name: 'Log in', exact: true }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

// Accepts every confirm() dialog of the page
export function acceptDialogs(page: Page) {
  page.on('dialog', (dialog) => dialog.accept())
}
