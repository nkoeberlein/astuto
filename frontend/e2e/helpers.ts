import { createHmac } from 'node:crypto'
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
  await page.goto(`/login?redirect=${encodeURIComponent(redirect)}`)
  await page.getByLabel('Email').fill(ADMIN.email)
  await page.getByLabel('Password', { exact: true }).fill(ADMIN.password)
  await page.getByRole('button', { name: 'Log in', exact: true }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

// Accepts every confirm() dialog of the page
export function acceptDialogs(page: Page) {
  page.on('dialog', (dialog) => dialog.accept())
}

// Current TOTP code (RFC 6238, SHA-1, 30 s, 6 digits) for a base32 secret, like an authenticator app
export function totp(secret: string, at = Date.now()): string {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
  let bits = ''
  for (const char of secret.replace(/\s|=/g, '').toUpperCase()) {
    bits += alphabet.indexOf(char).toString(2).padStart(5, '0')
  }
  const key = Buffer.from(bits.match(/.{8}/g)?.map((byte) => Number.parseInt(byte, 2)) ?? [])
  const counter = Buffer.alloc(8)
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 1000 / 30)))
  const hmac = createHmac('sha1', key).update(counter).digest()
  const offset = (hmac.at(-1) ?? 0) & 0xf
  const code = (hmac.readUInt32BE(offset) & 0x7fffffff) % 1_000_000
  return code.toString().padStart(6, '0')
}
