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

# Update or create database. Since Rails 7.1, db:version also prints a
# "database: <name>" line, so only the number is compared.
db_version=$(bundle exec rake db:version | sed -n 's/^Current version: //p')
echo "Database schema version: ${db_version:-unknown}"
if [ "$db_version" = "0" ]; then
  bundle exec rake db:create
  bundle exec rake db:schema:load
  bundle exec rake db:migrate
  bundle exec rake db:seed
else
  bundle exec rake db:migrate
fi
echo "Database prepared."