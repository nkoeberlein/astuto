import { test as setup } from '@playwright/test'
import { ADMIN_STATE, logIn } from './helpers'

// Logs in once for all admin tests: production limits logins to 5 per 20 s and IP
setup('log in as admin', async ({ page }) => {
  await logIn(page, '/')
  await page.context().storageState({ path: ADMIN_STATE })
})
