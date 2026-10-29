# Webhooks

Site settings › Webhooks sends an HTTP request whenever something happens in the feedback
space: a new post, a post waiting for approval, a deleted post, a status change, a new
comment, vote or user. URL and body are [Liquid](https://shopify.github.io/liquid/)
templates; the body must render valid JSON (use `| escape_json` on text variables). The
variables of each trigger are listed in the form and can be inserted with one click.

## Checking the signature

Every request carries three headers:

| Header | Content |
| --- | --- |
| `X-Astuto-Event` | the trigger, e.g. `new_post` |
| `X-Astuto-Timestamp` | Unix time of the request |
| `X-Astuto-Signature` | `sha256=` + HMAC-SHA256 of `"<timestamp>.<body>"` with the webhook's signing secret |

The signing secret (`whsec_…`) is shown when you edit the webhook; *New secret* replaces it.
Compare the signature in constant time and reject old timestamps (e.g. older than five
minutes) to stop replays.

Ruby:

```ruby
expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{raw_body}")}"
valid = ActiveSupport::SecurityUtils.secure_compare(expected, signature) &&
        (Time.now.to_i - timestamp.to_i).abs < 300
```

Node.js:

```js
import { createHmac, timingSafeEqual } from 'node:crypto'

const expected = `sha256=${createHmac('sha256', secret).update(`${timestamp}.${rawBody}`).digest('hex')}`
const valid =
  expected.length === signature.length &&
  timingSafeEqual(Buffer.from(expected), Buffer.from(signature)) &&
  Math.abs(Date.now() / 1000 - Number(timestamp)) < 300
```

Python:

```python
import hmac, hashlib, time

expected = 'sha256=' + hmac.new(secret.encode(), f'{timestamp}.{raw_body}'.encode(), hashlib.sha256).hexdigest()
valid = hmac.compare_digest(expected, signature) and abs(time.time() - int(timestamp)) < 300
```

Use the raw request body exactly as received, before parsing the JSON.

## Delivery log

*Deliveries* lists the newest 50 runs of a webhook: success or failure, HTTP status, duration,
and the error (template, JSON or network) or the start of the response. Tests from the
settings page appear there too, marked *Test*. Requests time out after 15 seconds. With
Sidekiq, failed deliveries are retried (each try shows up in the log).
