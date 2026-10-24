###
### Build stage ###
###
FROM ruby:4.0.9-trixie AS builder

RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN npm install -g yarn

ENV APP_ROOT /astuto
WORKDIR ${APP_ROOT}

# Build as development by default,
# unless --build-arg ENVIRONMENT=production is specificed
ARG ENVIRONMENT
ENV NODE_ENV=${ENVIRONMENT:-development}
ENV RAILS_ENV=${ENVIRONMENT:-development}

# Config bundler
RUN if [ "$ENVIRONMENT" = "production" ]; then bundle config set deployment true --local; fi
RUN if [ "$ENVIRONMENT" = "production" ]; then bundle config set without development test --local; fi
# yarn is already configured by NODE_ENV

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ${APP_ROOT}/
RUN bundle install

# Copy package.json and install packages
COPY package.json yarn.lock ${APP_ROOT}/
RUN yarn install --check-files

# Install v2 frontend packages (frontend/)
COPY frontend/package.json frontend/package-lock.json ${APP_ROOT}/frontend/
# --include=dev: Vite and friends are build tools; only the build output ships
RUN cd frontend && npm ci --include=dev --no-audit --no-fund

# Copy all files
COPY . ${APP_ROOT}/

# Build Swagger API documentation
RUN RSWAG_SWAGGERIZE=true RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# Compile assets if production
# SECRET_KEY_BASE=1 is a workaround (see https://github.com/rails/rails/issues/32947)
RUN if [ "$ENVIRONMENT" = "production" ]; then SECRET_KEY_BASE=1 ./bin/rails assets:precompile; fi

# Build v2 frontend into public/next if production
RUN if [ "$ENVIRONMENT" = "production" ]; then cd frontend && npm run build; fi

###
### Dev stage ###
###
FROM builder AS dev

ENTRYPOINT ["./docker-entrypoint-dev.sh"]

EXPOSE 3000

###
### Prod stage ###
###
FROM ruby:4.0.9-slim-trixie AS prod

RUN apt-get update -qq && \
  apt-get install -yq  \
  postgresql-client \
  nodejs && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  truncate -s 0 /var/log/*log


ENV APP_ROOT /astuto
WORKDIR ${APP_ROOT}

# Copy gems, packages and compiled assets
COPY --from=builder ${APP_ROOT}/vendor/bundle/ ${APP_ROOT}/vendor/bundle/
COPY --from=builder ${APP_ROOT}/node_modules/ ${APP_ROOT}/node_modules/
COPY --from=builder ${APP_ROOT}/public/ ${APP_ROOT}/public/

# Copy application code
COPY --from=builder ${APP_ROOT}/app/ ${APP_ROOT}/app/
COPY --from=builder ${APP_ROOT}/bin/ ${APP_ROOT}/bin/
COPY --from=builder ${APP_ROOT}/config/ ${APP_ROOT}/config/
COPY --from=builder ${APP_ROOT}/db/ ${APP_ROOT}/db/
COPY --from=builder ${APP_ROOT}/spec/ ${APP_ROOT}/spec/

# Copy scripts and configuration files
COPY --from=builder ${APP_ROOT}/docker-entrypoint.sh ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/docker-entrypoint-prod.sh ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/Gemfile ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/Gemfile.lock ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/.ruby-version ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/config.ru ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/Rakefile ${APP_ROOT}/
COPY --from=builder ${APP_ROOT}/lib/tasks/ ${APP_ROOT}/lib/tasks/
COPY --from=builder /usr/local/bundle/config /usr/local/bundle/config

# Copy Swagger API documentation
COPY --from=builder ${APP_ROOT}/swagger/ ${APP_ROOT}/swagger/

ENTRYPOINT ["./docker-entrypoint-prod.sh"]

EXPOSE 3000