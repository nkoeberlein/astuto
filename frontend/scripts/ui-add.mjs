// Adds shadcn/ui components: `npm run ui:add -- textarea label`.
// The shadcn CLI cannot read tsconfig `paths` without `baseUrl` (removed in TypeScript 7),
// so it imports `cn` from an unrelated npm package called "cn". This script fixes that.
import { execFileSync } from 'node:child_process'
import { readdirSync, readFileSync, writeFileSync } from 'node:fs'

const components = process.argv.slice(2)
if (components.length === 0) {
  console.error('Usage: npm run ui:add -- <component> [...]')
  process.exit(1)
}

const run = (command, args) => execFileSync(command, args, { stdio: 'inherit' })

run('npx', ['--yes', 'shadcn@4.22.1', 'add', ...components, '--yes'])

const dir = 'src/components/ui'
for (const file of readdirSync(dir)) {
  const path = `${dir}/${file}`
  const source = readFileSync(path, 'utf8')
  const fixed = source.replaceAll('from "cn"', 'from "@/lib/utils"')
  if (fixed !== source) writeFileSync(path, fixed)
}

const pkg = JSON.parse(readFileSync('package.json', 'utf8'))
if (pkg.dependencies?.cn) run('npm', ['uninstall', 'cn', '--no-audit', '--no-fund'])

run('npx', ['biome', 'check', '--write', dir])
