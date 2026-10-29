# Operations

Running Astuto Evolution in production: health checks, metrics, background jobs, several
instances, backups and Kubernetes. For the reverse proxy, HTTPS and SMTP see
[reverse-proxy-and-smtp.md](reverse-proxy-and-smtp.md).

## What makes up an installation

| Part | Notes |
|---|---|
| Web container (`ghcr.io/nkoeberlein/astuto-evo`) | Rails app, serves pages, API, MCP; port 3000 |
| PostgreSQL 18 | the only place with data; Astuto stores no files |
| Worker container (optional) | same image, runs Sidekiq; needs Redis 7 or newer |
| `SECRET_KEY_BASE` | keep it unchanged and back it up: sessions, API keys and the encrypted webhook settings depend on it |

On every start the container prepares the database: schema and seeds on a fresh database,
migrations otherwise. Containers that start at the same time take turns (Postgres advisory lock),
so web and worker containers or several replicas can start together.

## Health checks

| Path | Answers | Use for |
|---|---|---|
| `/health/live` | 200 as soon as the server answers, no dependencies | liveness probe |
| `/health/ready` | 200 with `{"status":"ok","checks":{...}}` when the database is reachable, no migrations are pending and, with Sidekiq, Redis answers; otherwise 503 with the failing checks | readiness probe, load balancer |
| `/health` | 200 `success` when the database answers (unchanged from 1.x) | existing setups |

They work over plain HTTP on the container's IP: `RAILS_HOSTS` and `FORCE_SSL` do not apply to
them.

Docker Compose:

```yaml
services:
  web:
    healthcheck:
      test: ["CMD", "ruby", "-rnet/http", "-e", "exit Net::HTTP.get_response(URI('http://localhost:3000/health/ready')).is_a?(Net::HTTPSuccess)"]
      interval: 30s
      start_period: 120s
```

## Metrics (Prometheus)

Set `METRICS_TOKEN` to a long random value; without it `/metrics` does not exist. Prometheus sends
the token as a bearer token:

```yaml
scrape_configs:
  - job_name: astuto
    metrics_path: /metrics
    authorization:
      type: Bearer
      credentials: <METRICS_TOKEN>
    static_configs:
      - targets: ['astuto:3000']
```

| Metric | Labels |
|---|---|
| `astuto_info` | `version` |
| `astuto_tenants` | `status` (active, pending, blocked) |
| `astuto_users`, `astuto_posts`, `astuto_comments`, `astuto_votes` | `tenant` (subdomain) |
| `astuto_posts_pending_approval` | `tenant`; worth an alert if moderators should react |
| `astuto_webhook_deliveries_last_hour` | `result` (success, failure); test deliveries excluded |
| `astuto_sidekiq_queue_size`, `astuto_sidekiq_queue_latency_seconds` | `queue` (with Sidekiq) |
| `astuto_sidekiq_jobs` | `set` (retry, dead) (with Sidekiq) |

All values are gauges computed on each scrape. For request rates and latencies use the reverse
proxy's metrics.

## Background jobs

Without configuration, jobs (emails, webhooks) run in a thread pool inside the web process. That
is fine for small installations, but jobs are lost on a restart, failed webhooks are not retried
and **recap emails are not sent**. For production use Sidekiq with Redis:

```yaml
services:
  web:
    environment:
      ACTIVE_JOB_BACKEND: sidekiq
      REDIS_URL: redis://redis:6379/0
  worker:
    image: ghcr.io/nkoeberlein/astuto-evo:2.0.0-alpha.3
    command: bundle exec sidekiq
    environment:
      # everything the web container gets, plus:
      ACTIVE_JOB_BACKEND: sidekiq
      REDIS_URL: redis://redis:6379/0
      # schedules the recap emails; set it on one worker only
      IS_SIDEKIQ: "true"
  redis:
    image: redis:8
```

`REDIS_PASSWORD` is passed separately from `REDIS_URL`, so special characters need no escaping;
`rediss://` URLs work. `SEND_RECAP_EMAIL_CRON` changes when recap emails go out (default
`0 15 * * *`, UTC). Queues come from `config/sidekiq.yml`.

## Several web instances

The web container keeps no state: sessions live in signed cookies and everything else in
PostgreSQL. Run as many instances as you like behind a load balancer; no sticky sessions are
needed. Every instance needs the same `SECRET_KEY_BASE`. Rate limiting (Rack::Attack) counts per
instance, so the effective limits grow with the number of instances. The general limit is 300
requests per 5 minutes per IP address; `RATE_LIMIT_REQUESTS` raises it when many people share one
address (e.g. an office behind NAT). With several instances,
use Sidekiq, so jobs survive restarts.

## Backup and restore

All data is in PostgreSQL; there are no uploaded files. Back up the database and your environment
(`SECRET_KEY_BASE` above all) together.

Backup with Docker Compose (custom format, compressed, consistent while the app runs):

```bash
docker compose exec -T db pg_dump -U astuto -Fc astuto > astuto-$(date +%F).dump
```

Daily at 03:00 with cron, keeping 14 days:

```bash
0 3 * * * cd /srv/astuto && docker compose exec -T db pg_dump -U astuto -Fc astuto > backups/astuto-$(date +\%F).dump && find backups -name '*.dump' -mtime +14 -delete
```

Restore into an empty database (stop web and worker first, so nothing writes in between):

```bash
docker compose stop web worker
```

```bash
docker compose exec -T db sh -c 'dropdb -U astuto astuto && createdb -U astuto astuto'
```

```bash
docker compose exec -T db pg_restore -U astuto -d astuto --no-owner < astuto-2026-10-29.dump
```

```bash
docker compose start web worker
```

On start the container applies migrations if the backup is from an older version. Test a restore
now and then, for example into a second database on another machine.

A dump restores into the same or a newer PostgreSQL major version; for upgrading PostgreSQL
itself see [UPGRADING.md](../UPGRADING.md).

## Kubernetes (Helm)

The chart in [`deploy/helm/astuto-evolution`](../deploy/helm/astuto-evolution) installs the web
deployment, an optional Sidekiq worker, service, ingress, Secret and an optional Prometheus
Operator ServiceMonitor, with the probes above. PostgreSQL and Redis are not part of it; use a
managed database or a separate chart.

```bash
helm install astuto deploy/helm/astuto-evolution \
  --set baseUrl=https://feedback.example.com \
  --set database.host=postgres.example.internal \
  --set secrets.secretKeyBase=$(openssl rand -hex 64) \
  --set secrets.databasePassword=... \
  --set ingress.enabled=true
```

Instead of `secrets.*` you can name an existing Secret in `existingSecret`. All options are
documented in [`values.yaml`](../deploy/helm/astuto-evolution/values.yaml). With `multiTenancy=true`,
add the wildcard host to the ingress (see [multi-tenancy.md](multi-tenancy.md)).
