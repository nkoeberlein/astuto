# Local CI for the Rails app: `docker compose exec web bin/ci`
# The frontend has its own checks (`npm run lint|typecheck|test|e2e` in frontend/,
# .github/workflows/frontend.yml and run-tests.yml).

CI.run do
  step "Security: Gem audit", "bin/bundler-audit check --update"
  step "Security: npm audit (frontend, critical only)", "cd frontend && npm audit --audit-level=critical"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: RSpec", "bundle exec rspec"
  # Seeds must load cleanly; truncate afterwards so the next RSpec run starts from an empty test DB
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant && env RAILS_ENV=test bin/rails db:truncate_all"
end
