# Reverse Proxy, HTTPS, Database & SMTP Configuration Guide

This guide covers the most common production deployment setups for Astuto Evolution: running behind an HTTPS reverse proxy, custom CA certificates, external PostgreSQL databases, and SMTP providers.

---

## 1. Reverse Proxy & HTTPS (`#478`, `#201`)

When running Astuto behind a TLS-terminating reverse proxy (nginx, Caddy, Traefik), the proxy forwards HTTP traffic to the container (`http://web:3000`). For OAuth callback URLs (`https://...`) and Rails CSRF `Origin` checks to work properly:

1. **Set `BASE_URL` and `ASSUME_SSL=true`** in your environment:
   ```env
   BASE_URL=https://feedback.example.com
   ASSUME_SSL=true
   # Optional: set FORCE_SSL=true if you also want Rails to send HSTS headers and redirect HTTP -> HTTPS itself
   FORCE_SSL=false
   # Optional: comma-separated list of additional allowed Host headers
   RAILS_HOSTS=feedback.example.com
   ```
2. **Forward `X-Forwarded-Proto: https` and `Host`** from your reverse proxy.

### nginx

```nginx
server {
    listen 443 ssl http2;
    server_name feedback.example.com;

    ssl_certificate     /etc/letsencrypt/live/feedback.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/feedback.example.com/privkey.pem;

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_set_header   X-Forwarded-Host  $host;
    }
}
```

### Caddy (`Caddyfile`)

Caddy sets `X-Forwarded-For`, `X-Forwarded-Proto`, and `X-Forwarded-Host` automatically:

```caddyfile
feedback.example.com {
    reverse_proxy web:3000
}
```

### Traefik (`docker-compose.yml` labels)

```yaml
services:
  web:
    environment:
      - BASE_URL=https://feedback.example.com
      - ASSUME_SSL=true
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.astuto.rule=Host(`feedback.example.com`)"
      - "traefik.http.routers.astuto.entrypoints=websecure"
      - "traefik.http.routers.astuto.tls.certresolver=letsencrypt"
      - "traefik.http.services.astuto.loadbalancer.server.port=3000"
```

---

## 2. Custom / Self-Signed CA Certificates (`#203`)

If your OAuth2/OIDC identity provider (e.g., internal Keycloak, GitLab, ADFS) or SMTP server uses an internal corporate CA certificate:

1. Mount your `.crt` file(s) into `/usr/local/share/ca-certificates/` inside the `web` container:
   ```yaml
   services:
     web:
       volumes:
         - ./certs/corporate-root-ca.crt:/usr/local/share/ca-certificates/corporate-root-ca.crt:ro
   ```
2. On container startup, `docker-entrypoint.sh` automatically detects `.crt` files in `/usr/local/share/ca-certificates` and runs `update-ca-certificates` before booting Rails.
3. Alternatively, set `SSL_CERT_FILE=/path/to/custom-ca-bundle.pem` in the container environment.

---

## 3. PostgreSQL Configuration (`#326`, `#207`)

Astuto Evolution supports separating the database name from the PostgreSQL username, or using a single `DATABASE_URL` connection string for managed cloud databases (AWS RDS, Supabase, Hetzner, Cloud SQL):

```env
# Option A: Individual variables (POSTGRES_DB defaults to POSTGRES_USER if omitted)
POSTGRES_HOST=db.internal.example.com
POSTGRES_PORT=5432
POSTGRES_USER=astuto_user
POSTGRES_PASSWORD=supersecret
POSTGRES_DB=astuto_production

# Option B: Full connection URL (overrides individual settings)
DATABASE_URL=postgresql://astuto_user:supersecret@db.internal.example.com:5432/astuto_production?pool=10
```

---

## 4. SMTP Configuration Examples (`#330`, `#446`, `#294`, `#385`)

> **Important:** Most SMTP providers require `EMAIL_SMTP_AUTH=login` (or `plain`). Starting with Astuto Evolution 2.0, `EMAIL_SMTP_OPENSSL_VERIFY_MODE` defaults to `peer` for TLS security, and all delivery errors are logged even when `EMAIL_RAISE_DELIVERY_ERRORS=false`.

**Sender:** `EMAIL_MAIL_FROM`; without it, emails come from `noreply@<host of BASE_URL>`. `EMAIL_MAIL_REPLY_TO` defaults to the sender. Many providers only accept a sender of a verified domain.

**Check the setup:** Site settings › General › Emails › *Send test email* sends a message to you at once and shows the server's error message if it fails (wrong password, blocked port, unverified sender).

### Amazon SES (STARTTLS on Port 587)

```env
EMAIL_DELIVERY_METHOD=smtp
EMAIL_SMTP_HOST=email-smtp.eu-central-1.amazonaws.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_AUTH=login
EMAIL_SMTP_USER=AKIAIOSFODNN7EXAMPLE
EMAIL_SMTP_PASS=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EMAIL_SMTP_STARTTLS_AUTO=true
EMAIL_SMTP_TLS=false
EMAIL_SMTP_OPENSSL_VERIFY_MODE=peer
EMAIL_MAIL_FROM=noreply@feedback.example.com
EMAIL_MAIL_REPLY_TO=support@example.com
```

### Brevo / Sendinblue (Port 587)

```env
EMAIL_DELIVERY_METHOD=smtp
EMAIL_SMTP_HOST=smtp-relay.brevo.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_AUTH=login
EMAIL_SMTP_USER=your-login@example.com
EMAIL_SMTP_PASS=xsmtpsib-xxxxxxxxxxxxxxxx
EMAIL_SMTP_STARTTLS_AUTO=true
EMAIL_SMTP_TLS=false
EMAIL_MAIL_FROM=noreply@feedback.example.com
```

### SMTP2GO (Port 587 or 2525)

```env
EMAIL_DELIVERY_METHOD=smtp
EMAIL_SMTP_HOST=mail.smtp2go.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_AUTH=login
EMAIL_SMTP_USER=astuto-smtp-user
EMAIL_SMTP_PASS=your-smtp2go-password
EMAIL_SMTP_STARTTLS_AUTO=true
EMAIL_SMTP_TLS=false
EMAIL_MAIL_FROM=noreply@feedback.example.com
```

### Microsoft Exchange / Microsoft 365 (Port 587)

```env
EMAIL_DELIVERY_METHOD=smtp
EMAIL_SMTP_HOST=smtp.office365.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_HELO_DOMAIN=example.com
EMAIL_SMTP_AUTH=login
EMAIL_SMTP_USER=noreply@example.com
EMAIL_SMTP_PASS=your-app-password
EMAIL_SMTP_STARTTLS_AUTO=true
EMAIL_SMTP_TLS=false
EMAIL_MAIL_FROM=noreply@example.com
```
