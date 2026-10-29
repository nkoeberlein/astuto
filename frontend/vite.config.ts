import path from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import { tanstackRouter } from '@tanstack/router-plugin/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vitest/config'

// Rails backend for the dev proxy: http://web:3000 inside docker compose,
// or e.g. http://localhost:3456 when running Vite on the host.
const backend = process.env.BACKEND_URL ?? 'http://localhost:3000'

// Paths that Rails serves: the app API, Devise and OAuth pages, legacy assets
const proxied = ['/api', '/users', '/o_auths', '/assets', '/rails']

export default defineConfig(({ command }) => ({
  // Built files live under /next/assets; Rails serves the pages themselves at / (SpaController).
  // The dev server serves everything at /.
  base: command === 'build' ? '/next/' : '/',
  plugins: [tanstackRouter({ target: 'react', autoCodeSplitting: true }), react(), tailwindcss()],
  resolve: {
    alias: { '@': path.resolve(import.meta.dirname, 'src') },
  },
  build: {
    outDir: '../public/next',
    emptyOutDir: true,
  },
  server: {
    host: true,
    port: 5173,
    strictPort: true,
    // Keep the browser's Host header so Rails' CSRF origin check matches
    proxy: Object.fromEntries(proxied.map((p) => [p, { target: backend, changeOrigin: false }])),
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    css: false,
  },
}))
