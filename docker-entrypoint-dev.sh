#!/bin/sh

set -e

sh docker-entrypoint.sh

# Generate Swagger documentation (don't know why it's not passed from container to host)
echo "Generating Swagger documentation..."
bundle exec rake rswag:specs:swaggerize
echo "Swagger documentation generated."

# The frontend runs in its own container (Vite, http://localhost:5173)
exec bin/rails server -b 0.0.0.0 -p 3000