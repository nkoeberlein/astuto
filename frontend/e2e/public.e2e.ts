import { expect, test } from '@playwright/test'

test.describe('public pages', () => {
  test('home and roadmap page @mobile', async ({ page }) => {
    await page.goto('/next/')
    const boardLink = page.getByRole('navigation', { name: 'Boards' }).getByRole('link').last()
    await expect(boardLink).toBeVisible()

    await page.goto('/next/roadmap')
    await expect(page.getByRole('heading', { name: 'Roadmap', level: 1 })).toBeVisible()
  })

  test('embedded roadmap has no header and can be framed', async ({ page, request }) => {
    const response = await request.get('/next/embedded_roadmap')
    expect(response.headers()['x-frame-options']).toBeUndefined()
    expect((await request.get('/next/roadmap')).headers()['x-frame-options']).toBe('SAMEORIGIN')

    await page.goto('/next/embedded_roadmap?show_board_filter=false')
    await expect(page.locator('header')).toHaveCount(0)
    await expect(page.getByRole('heading', { level: 1 })).toHaveCount(0)
  })

  test('settings and moderation send visitors to the login page', async ({ page }) => {
    await page.goto('/next/site_settings/general')
    await expect(page).toHaveURL(/\/next\/login\?redirect=%2Fsite_settings%2Fgeneral/)
    await page.goto('/next/moderation/users')
    await expect(page).toHaveURL(/\/next\/login/)
  })

  test('wrong password shows an error', async ({ page }) => {
    await page.goto('/next/login')
    await page.getByLabel('Email').fill('nobody@example.com')
    await page.getByLabel('Password', { exact: true }).fill('wrong-password')
    await page.getByRole('button', { name: 'Log in', exact: true }).click()
    await expect(page.getByRole('alert')).toBeVisible()
  })
})
