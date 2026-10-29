#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f $APP_ROOT/tmp/pids/server.pid

# Load custom CA certificates if mounted in /usr/local/share/ca-certificates (#203)
if [ -d /usr/local/share/ca-certificates ] && [ -n "$(ls -A /usr/local/share/ca-certificates/*.crt 2>/dev/null)" ]; then
  if command -v update-ca-certificates >/dev/null 2>&1; then
    echo "Updating CA certificates..."
    update-ca-certificates || echo "Warning: update-ca-certificates failed; use SSL_CERT_FILE if running unprivileged."
  fi
fi

# Prepare database
echo "Preparing database..."

# Wait for database
until bundle exec rake db:version; do
  >&2 echo "Waiting for postgres to initialize..."
  sleep 1
done

# Schema and seeds on a fresh database, migrations otherwise; one container at a time
bundle exec rake astuto:prepare_db
echo "Database prepared."