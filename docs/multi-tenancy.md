# Multi-tenancy

One Astuto Evolution instance can host several feedback spaces, for example one per product,
brand or customer. Each feedback space has its own subdomain (`acme.feedback.example.com`),
optionally its own domain (`ideas.acme.com`), and its own boards, users, settings, webhooks and
API keys. Accounts are per feedback space: the same email address can sign up in several of them,
and a login is valid only in the space it was made in.

Without `MULTI_TENANCY=true` (the default) the instance has exactly one feedback space at the
`BASE_URL` host. Nothing on this page applies then.

## Setup

```env
MULTI_TENANCY=true
BASE_URL=https://feedback.example.com
# The leading dot allows the host and all its subdomains. Custom domains of feedback spaces
# are allowed automatically.
RAILS_HOSTS=.feedback.example.com
ASSUME_SSL=true
```

Subdomains are whatever stands in front of the `BASE_URL` host, so `feedback.example.co.uk` or
`localhost` work as well. These subdomains are reserved and never belong to a feedback space:
`login` (OAuth callbacks of the instance's default providers), `api`, `admin`, `docs`, `help` and a
few more (`config/initializers/reserved_subdomains.rb`).

### DNS

Point the base host and a wildcard at the server:

```
feedback.example.com.     A      203.0.113.10
*.feedback.example.com.   CNAME  feedback.example.com.
```

### TLS

Either a wildcard certificate for `*.feedback.example.com` (needs a DNS challenge at your DNS
provider), or Caddy's on-demand TLS, which also covers custom domains. Caddy asks Astuto before
each new certificate; `/custom_domain_check?domain=<host>` answers 200 for the base host, for
subdomains of feedback spaces and for their custom domains, and 404 for everything else (also for
blocked feedback spaces), so nobody can make Caddy request certificates for arbitrary hosts:

```caddyfile
{
    on_demand_tls {
        ask http://astuto:3000/custom_domain_check
    }
}

https:// {
    tls {
        on_demand
    }
    reverse_proxy astuto:3000
}
```

Caddy sends `X-Forwarded-Proto` and `Host` on its own; for nginx or Traefik see
[reverse-proxy-and-smtp.md](reverse-proxy-and-smtp.md).

## Feedback spaces

There is no self-service sign-up for new feedback spaces. The operator creates them on the
instance admin page or with rake tasks.

### Instance admin page

Set a password and open `/instance` on the `BASE_URL` host (`https://feedback.example.com/instance`);
the user name is `admin`:

```env
INSTANCE_ADMIN_PASSWORD=<long random password>
```

The page lists all feedback spaces with their address, status and numbers of users and posts, and
creates, edits (name, custom domain, language), blocks, unblocks and deletes them. Deleting asks
for the subdomain as confirmation and removes all data of the feedback space. Without
`INSTANCE_ADMIN_PASSWORD`, on feedback space hosts and without multi-tenancy, `/instance` does not
exist (404). Requests are rate-limited per IP; serve the instance over HTTPS, because HTTP Basic
auth sends the password with every request.

### Rake tasks

In Docker, prefix them with `docker compose exec web`:

```bash
bin/rails tenants:create SUBDOMAIN=acme NAME="Acme" OWNER_EMAIL=owner@acme.example LOCALE=de
```

```bash
bin/rails tenants:list
```

```bash
bin/rails tenants:block SUBDOMAIN=acme
```

```bash
bin/rails tenants:unblock SUBDOMAIN=acme
```

`tenants:create` (like the admin page) creates the feedback space with the welcome boards and an
owner account with a confirmed email address, and prints a random password for it. The owner
should change it after the first login. A blocked feedback space shows a "blocked" page; its data stays.

## Custom domains

The owner or an admin enters the domain in Site settings › General › Custom domain (or the
operator on the instance admin page), after adding a CNAME record that points the domain at the
instance (for example at `acme.feedback.example.com`).
The page then works under both addresses. Rails' host check allows the custom domain as soon as it
is saved, and Caddy's on-demand TLS gets a certificate on the first request. With another proxy,
add the domain and a certificate there.

Links in emails always use the custom domain when one is set.

OAuth login works on both addresses. Providers always call back on the subdomain (or on
`login.<BASE_URL host>` for the instance's default providers), so register that callback URL with
the provider; a login started on the custom domain is finished there automatically.

## Languages and emails

Each feedback space has its own language (Site settings › General), optionally replaced by the
visitor's browser language. Emails are sent from `EMAIL_MAIL_FROM` for all feedback spaces; the
sender name is the feedback space's name.
