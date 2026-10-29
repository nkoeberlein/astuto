import { expect, test } from '@playwright/test'

test.describe('public pages', () => {
  test('home and roadmap page @mobile', async ({ page }) => {
    await page.goto('/')
    const boardLink = page.getByRole('navigation', { name: 'Boards' }).getByRole('link').last()
    await expect(boardLink).toBeVisible()

    await page.goto('/roadmap')
    await expect(page.getByRole('heading', { name: 'Roadmap', level: 1 })).toBeVisible()
  })

  test('embedded roadmap has no header and can be framed', async ({ page, request }) => {
    const response = await request.get('/embedded_roadmap')
    expect(response.headers()['x-frame-options']).toBeUndefined()
    expect((await request.get('/roadmap')).headers()['x-frame-options']).toBe('SAMEORIGIN')

    await page.goto('/embedded_roadmap?show_board_filter=false')
    await expect(page.locator('header')).toHaveCount(0)
    await expect(page.getByRole('heading', { level: 1 })).toHaveCount(0)
  })

  test('settings and moderation send visitors to the login page', async ({ page }) => {
    await page.goto('/site_settings/general')
    await expect(page).toHaveURL(/\/login\?redirect=%2Fsite_settings%2Fgeneral/)
    await page.goto('/moderation/users')
    await expect(page).toHaveURL(/\/login/)
  })

  test('wrong password shows an error', async ({ page }) => {
    await page.goto('/login')
    await page.getByLabel('Email').fill('nobody@example.com')
    await page.getByLabel('Password', { exact: true }).fill('wrong-password')
    await page.getByRole('button', { name: 'Log in', exact: true }).click()
    await expect(page.getByRole('alert')).toBeVisible()
  })

  test('old addresses lead to the new pages', async ({ page }) => {
    await page.goto('/next/roadmap?sort=recently_updated')
    await expect(page).toHaveURL(/\/roadmap\?sort=recently_updated$/)
    await page.goto('/users/sign_in')
    await expect(page).toHaveURL(/\/login$/)
    await page.goto('/users/password/new')
    await expect(page).toHaveURL(/\/password\/forgot$/)
    await page.goto('/users/password/edit?reset_password_token=abc')
    await expect(page).toHaveURL(/\/password\/reset\?reset_password_token=abc$/)
  })

  test('pages load without Content Security Policy violations', async ({ page }) => {
    const violations: string[] = []
    page.on('console', (message) => {
      if (/Content Security Policy|Refused to (execute|load|apply)/i.test(message.text())) {
        violations.push(message.text())
      }
    })
    for (const path of ['/', '/roadmap', '/boards/feature-requests', '/login', '/register']) {
      await page.goto(path)
      await page.waitForLoadState('networkidle')
    }
    expect(violations).toEqual([])
  })
})
