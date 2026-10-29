#!/bin/sh

set -e

sh docker-entrypoint.sh

# Without arguments the container runs the web server. With arguments it runs them after
# preparing the database, e.g. `bundle exec sidekiq` for a worker (docs/operations.md).
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec bundle exec rails server -e production
