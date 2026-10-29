# Appearance

## Name, logo and links (Site settings › General)

| Setting | Effect |
| --- | --- |
| Site name | header, page titles, emails |
| Logo, favicon | URLs of images; the favicon falls back to the Astuto icon |
| Brand display | name and logo, only the name, only the logo, or nothing |
| Logo links to | home page, your own URL, or nowhere |
| Header links | extra links in the header, one `Label\|https://...` per line (http(s), `mailto:` and site paths only) |
| Logo size in emails | pixels, default 64 |

## Custom CSS (Site settings › Appearance)

The CSS is added to every page after the built-in styles; the form shows unsaved changes as a
live preview. The simplest and most stable way is to change the **colour tokens** the whole
interface is built from:

```css
:root {
  --primary: oklch(0.55 0.2 260);          /* buttons, links, active navigation */
  --primary-foreground: oklch(0.99 0 0);   /* text on primary */
  --radius: 0.25rem;                       /* corner radius of cards, buttons, inputs */
  --background: oklch(0.99 0 0);
}

/* Dark mode follows the visitor's system setting */
@media (prefers-color-scheme: dark) {
  :root {
    --primary: oklch(0.7 0.15 260);
  }
}
```

All tokens: `--background`, `--foreground`, `--card`, `--card-foreground`, `--popover`,
`--popover-foreground`, `--primary`, `--primary-foreground`, `--secondary`,
`--secondary-foreground`, `--muted`, `--muted-foreground`, `--accent`, `--accent-foreground`,
`--destructive`, `--border`, `--input`, `--ring`, `--radius`. Any CSS colour format works.

Other selectors (classes of single elements) are not a stable interface and may change between
releases. The CSS cannot leave its `<style>` element, and JavaScript is not possible (Content
Security Policy).

## Embedding

- Roadmap only, in an iframe: Site settings › Roadmap shows the embed code (`/embedded_roadmap`).
- Feedback button with boards, roadmap and changelog, with visitor sign-in: [widget.md](widget.md).
