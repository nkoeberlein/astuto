# Feedback widget

A feedback button for your own website or app. It opens a panel with your boards (vote, post),
the roadmap and the changelog. Visitors who are signed in to **your** app vote and post under
their own Astuto account, without signing in a second time.

## 1. Turn it on

Site settings › Widget: turn on the widget and, recommended, enter the sites that may show it
(one origin per line, e.g. `https://app.example.com`). With an empty list any site may.

## 2. Add the script

```html
<script src="https://feedback.example.com/widget.js" data-token="VISITOR_TOKEN" defer></script>
```

| Attribute | Meaning |
| --- | --- |
| `data-token` | visitor token from your server (below); leave it out for anonymous visitors |
| `data-label` | button text, default `Feedback` |
| `data-position` | `end` (default) or `start`; follows the writing direction of your page |
| `data-color` | button background, e.g. `#0f766e` |

JavaScript API: `AstutoWidget.open()`, `AstutoWidget.close()`, `AstutoWidget.identify(token)`
after your user signs in, `AstutoWidget.identify(null)` after they sign out.

## 3. Sign visitors in

Your server creates a JSON Web Token, signed with HS256 and the **widget secret** from Site
settings › Widget. Keep the secret on the server; never send it to the browser.

| Claim | |
| --- | --- |
| `email` | required |
| `name` | display name |
| `id` | your user id (recommended): links the account, also when the email changes later |
| `exp` | required, at most one day ahead; a short lifetime (an hour) is enough |

Node.js:

```js
import jwt from 'jsonwebtoken'

const visitorToken = jwt.sign(
  { email: user.email, name: user.name, id: String(user.id) },
  process.env.ASTUTO_WIDGET_SECRET,
  { algorithm: 'HS256', expiresIn: '1h' },
)
```

Ruby (`jwt` gem):

```ruby
token = JWT.encode({ email: user.email, name: user.name, id: user.id.to_s, exp: 1.hour.from_now.to_i },
                   ENV.fetch('ASTUTO_WIDGET_SECRET'), 'HS256')
```

Python (`PyJWT`):

```python
token = jwt.encode({'email': user.email, 'name': user.name, 'id': str(user.id),
                    'exp': int(time.time()) + 3600}, os.environ['ASTUTO_WIDGET_SECRET'], algorithm='HS256')
```

Astuto finds the account by `id`, else by `email` (and links it to the `id`), else creates one
(unless *Create an account for new visitors* is off). The email counts as confirmed, since your
app vouches for it. An email that already belongs to an account linked to a different `id` is
refused.

**Moderators and admins are never signed in through the widget.** Whoever holds the secret
could otherwise act as staff; they sign in on the feedback site.

## How it works

- `widget.js` adds the button and, on the first click, an iframe of `/embed`. The visitor token
  goes to the iframe by `postMessage`, only to the feedback site's origin, never in a URL.
- The iframe trades it for an access token (`POST /api/app/v1/widget/session`, valid 12 hours)
  and sends that as `Authorization: Bearer` with its API requests. Browsers block cookies in
  iframes on other sites, so the widget does not rely on them; requests with the bearer token
  need no CSRF token, because browsers never add that header by themselves.
- Posts open on the full feedback site in a new tab.
- **New secret** in the settings invalidates all visitor tokens signed with the old one (access
  tokens that were already handed out stay valid until they expire).
- Private feedback spaces work too: signed-in widget visitors see the content.

The existing embeddable roadmap (`/embedded_roadmap`, Site settings › Roadmap) stays available
for showing only the roadmap on a page.
