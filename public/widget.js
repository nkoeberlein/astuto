/*
 * Astuto Evolution feedback widget (docs/widget.md)
 *
 *   <script src="https://feedback.example.com/widget.js" data-token="VISITOR_TOKEN" defer></script>
 *
 * Options (data-* attributes): token (visitor token signed by your server; leave it out for
 * anonymous visitors), label (button text, default "Feedback"), position ("end" or "start"),
 * color (button background). JavaScript API: AstutoWidget.open(), .close(), .identify(token),
 * .identify(null) to sign out.
 *
 * The panel is an iframe of <feedback site>/embed. The visitor token goes there by postMessage
 * (never in the URL), only to the feedback site's origin.
 */
;(() => {
  const script = document.currentScript
  if (!script || window.AstutoWidget) return

  const origin = new URL(script.src).origin
  const options = script.dataset
  let token = options.token || null
  let frame = null
  let panel = null
  let ready = false
  let open = false

  const side = options.position === 'start' ? 'inset-inline-start' : 'inset-inline-end'

  const send = (message) => {
    if (frame && ready) frame.contentWindow.postMessage(message, origin)
  }

  const identify = (newToken) => {
    token = newToken || null
    send(token ? { type: 'astuto:identify', token } : { type: 'astuto:logout' })
  }

  const button = document.createElement('button')
  button.type = 'button'
  button.textContent = options.label || 'Feedback'
  button.setAttribute('aria-expanded', 'false')
  button.style.cssText = [
    'position:fixed',
    `${side}:20px`,
    'inset-block-end:20px',
    'z-index:2147483000',
    'padding:10px 16px',
    'border:0',
    'border-radius:9999px',
    `background:${options.color || '#111827'}`,
    'color:#fff',
    'font:600 14px/1.2 system-ui,sans-serif',
    'box-shadow:0 4px 14px rgba(0,0,0,.2)',
    'cursor:pointer',
  ].join(';')

  const build = () => {
    panel = document.createElement('div')
    panel.setAttribute('role', 'dialog')
    panel.setAttribute('aria-label', button.textContent)
    panel.style.cssText = [
      'position:fixed',
      `${side}:20px`,
      'inset-block-end:76px',
      'z-index:2147483000',
      'width:min(400px,calc(100vw - 40px))',
      'height:min(640px,calc(100vh - 100px))',
      'border-radius:12px',
      'overflow:hidden',
      'background:#fff',
      'box-shadow:0 10px 40px rgba(0,0,0,.25)',
    ].join(';')
    frame = document.createElement('iframe')
    frame.src = `${origin}/embed`
    frame.title = button.textContent
    frame.style.cssText = 'width:100%;height:100%;border:0'
    panel.appendChild(frame)
    document.body.appendChild(panel)
  }

  const toggle = (show) => {
    open = show
    if (open && !panel) build()
    if (panel) panel.style.display = open ? 'block' : 'none'
    button.setAttribute('aria-expanded', String(open))
    if (!open) button.focus()
  }

  window.addEventListener('message', (event) => {
    if (event.origin !== origin || !frame || event.source !== frame.contentWindow) return
    const type = event.data && event.data.type
    if (type === 'astuto:ready') {
      ready = true
      if (token) send({ type: 'astuto:identify', token })
    }
    if (type === 'astuto:close') toggle(false)
  })

  document.addEventListener('keydown', (event) => {
    if (open && event.key === 'Escape') toggle(false)
  })

  button.addEventListener('click', () => toggle(!open))

  const mount = () => document.body.appendChild(button)
  if (document.body) mount()
  else document.addEventListener('DOMContentLoaded', mount)

  window.AstutoWidget = {
    open: () => toggle(true),
    close: () => toggle(false),
    identify,
  }
})()
