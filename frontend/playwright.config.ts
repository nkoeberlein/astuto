import { defineConfig, devices } from '@playwright/test'

// End-to-end tests against a running instance (Rails serving the built frontend under /next):
//   E2E_BASE_URL=http://localhost:3000 E2E_ADMIN_PASSWORD=... npm run e2e
// The tests share one database, so they run one after another.
export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.e2e.ts',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    trace: 'retain-on-failure',
    locale: 'en-US',
  },
  projects: [
    { name: 'setup', testMatch: '**/*.setup.ts' },
    { name: 'desktop', use: { ...devices['Desktop Chrome'] }, dependencies: ['setup'] },
    { name: 'mobile', use: { ...devices['Pixel 7'] }, grep: /@mobile/ },
  ],
})
