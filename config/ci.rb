# Local CI for the Rails app: `docker compose exec web bin/ci`
# The frontend has its own checks (`npm run lint|typecheck|test|e2e` in frontend/,
# .github/workflows/frontend.yml and run-tests.yml).

CI.run do
  step "Security: Gem audit", "bin/bundler-audit check --update"
  step "Security: npm audit (frontend, critical only)", "cd frontend && npm audit --audit-level=critical"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  # bin/ci runs inside the app bundle: `bundler/setup` leaves RUBYOPT and BUNDLE_* in the
  # environment, so a child `bundle` would boot the not-yet-installed lint bundle (crash on the
  # first run) and resolve its lock into the app's Gemfile.lock. Strip the inherited variables and
  # point at the lint bundle explicitly; BUNDLE_APP_CONFIG (= /usr/local/bundle) stays.
  lint_env = "env -u RUBYOPT -u BUNDLE_GEMFILE -u BUNDLE_BIN_PATH -u BUNDLE_LOCKFILE -u BUNDLER_SETUP BUNDLE_GEMFILE=lint/Gemfile"
  step "Lint: RuboCop", "#{lint_env} bundle install --quiet && #{lint_env} bundle exec rubocop"
  step "Tests: RSpec", "bundle exec rspec"
  # Seeds must load cleanly; truncate afterwards so the next RSpec run starts from an empty test DB
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant && env RAILS_ENV=test bin/rails db:truncate_all"
end
