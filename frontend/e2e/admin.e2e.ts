import { expect, test } from '@playwright/test'
import { ADMIN_STATE, acceptDialogs, unique } from './helpers'

const COMMENT_PLACEHOLDER = 'Leave a comment'
const COMMENT_SUBMIT = 'Submit'

test.describe('admin journey', () => {
  test.use({ storageState: ADMIN_STATE })

  test('board, post, vote, comment and cleanup', async ({ page }) => {
    acceptDialogs(page)
    const boardName = unique('E2E Board')
    const postTitle = unique('E2E idea')

    await page.goto('/site_settings/boards')

    // Create a board: it shows up in the header
    await page.getByRole('button', { name: 'New' }).click()
    await page.getByLabel('Board name').fill(boardName)
    await page.getByRole('button', { name: 'Create', exact: true }).click()
    const headerLink = page
      .getByRole('navigation', { name: 'Boards' })
      .getByRole('link', { name: boardName })
    await expect(headerLink).toBeVisible()

    try {
      // Post on it (admins skip approval), vote and comment
      await headerLink.click()
      await page.getByRole('button', { name: 'Submit feedback' }).click()
      await page.getByLabel('Title').fill(postTitle)
      await page.waitForTimeout(2100) // the anti-spam check rejects forms sent within 2 s
      await page.locator('form').getByRole('button', { name: 'Submit feedback' }).click()
      // The new post opens right away
      await expect(page.getByRole('heading', { name: postTitle, level: 1 })).toBeVisible()

      const vote = page.getByRole('button', { name: /^Likes: \d+/ }).first()
      await vote.click()
      await expect(vote).toHaveAccessibleName(/^Likes: 1/)

      const comment = page.getByRole('textbox', { name: COMMENT_PLACEHOLDER })
      await comment.fill('A comment from the e2e test')
      await page.getByRole('button', { name: COMMENT_SUBMIT }).click()
      await expect(page.getByText('A comment from the e2e test')).toBeVisible()
    } finally {
      // Clean up: deleting the board deletes its posts
      await page.goto('/site_settings/boards')
      await page.getByRole('button', { name: `${boardName}: Delete` }).click()
      await expect(
        page.getByRole('navigation', { name: 'Boards' }).getByRole('link', { name: boardName }),
      ).toHaveCount(0)
    }
  })

  test('settings, moderation and profile pages load', async ({ page }) => {
    for (const [path, heading] of [
      ['/site_settings/general', 'General'],
      ['/site_settings/post_statuses', 'Statuses'],
      ['/site_settings/roadmap', 'Roadmap'],
      ['/site_settings/authentication', 'Authentication'],
      ['/site_settings/appearance', 'Appearance'],
      ['/site_settings/webhooks', 'Webhooks'],
      ['/site_settings/invitations', 'Invitations'],
      ['/moderation/feedback', 'Moderation'],
      ['/moderation/users', 'Moderation'],
      ['/profile', 'Profile settings'],
    ] as const) {
      await page.goto(path)
      await expect(page.getByRole('heading', { name: heading }).first()).toBeVisible()
    }
  })

  test('saving general settings shows up in the header', async ({ page }) => {
    await page.goto('/site_settings/general')
    const siteName = page.getByLabel('Site name')
    const original = await siteName.inputValue()
    const changed = unique('E2E Site')

    await siteName.fill(changed)
    await page.getByRole('button', { name: 'Save' }).click()
    await expect(page.locator('header')).toContainText(changed)

    await siteName.fill(original)
    await page.getByRole('button', { name: 'Save' }).click()
    await expect(page.locator('header')).toContainText(original)
  })

  test('anonymous feedback waits for approval', async ({ page, browser }) => {
    acceptDialogs(page)
    const title = unique('E2E anonymous idea')

    // A visitor submits feedback anonymously (default policy: anonymous posts need approval)
    // New contexts inherit the admin session from test.use: start this one signed out
    const visitorContext = await browser.newContext({ storageState: { cookies: [], origins: [] } })
    const visitor = await visitorContext.newPage()
    await visitor.goto('/boards/feature-requests')
    await visitor.getByRole('button', { name: 'Submit feedback' }).click()
    await visitor.getByLabel('Title').fill(title)
    await visitor.waitForTimeout(2100)
    await visitor.getByRole('button', { name: 'Submit anonymously' }).click()
    await expect(visitor.getByText(/pending moderator approval/)).toBeVisible()
    await visitorContext.close()

    // The moderator approves it from the queue; then it shows on the board
    await page.goto('/moderation/feedback')
    const item = page.getByRole('listitem').filter({ hasText: title })
    await item.getByRole('button', { name: 'Approve' }).click()
    await expect(item).toHaveCount(0)

    await page.goto('/boards/feature-requests')
    await expect(page.getByRole('link', { name: title })).toBeVisible()

    // Clean up through the post page
    await page.getByRole('link', { name: title }).click()
    await page.getByRole('button', { name: 'Delete' }).first().click()
    await expect(page).toHaveURL(/\/boards\/feature-requests/)
  })
})
