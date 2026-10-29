import { X } from 'lucide-react'
import { useState } from 'react'
import { cn } from '@/lib/utils'

type Flash = { notice?: string; alert?: string }

// Notices of Rails pages that redirect into the app, e.g. "Your email address has been
// confirmed" (SpaController puts them into <meta name="astuto-flash">). Shown once.
export function readFlash(doc: Document = document): Flash {
  const content = doc.querySelector<HTMLMetaElement>('meta[name="astuto-flash"]')?.content
  if (!content) return {}
  try {
    const parsed: unknown = JSON.parse(content)
    if (typeof parsed !== 'object' || parsed === null) return {}
    const { notice, alert } = parsed as Record<string, unknown>
    return {
      notice: typeof notice === 'string' ? notice : undefined,
      alert: typeof alert === 'string' ? alert : undefined,
    }
  } catch {
    return {}
  }
}

export function FlashMessages() {
  const [flash, setFlash] = useState(readFlash)
  const entries = (['alert', 'notice'] as const).filter((kind) => flash[kind])
  if (entries.length === 0) return null

  return (
    <div className="space-y-2 px-4 pt-4 sm:px-6 lg:px-10">
      {entries.map((kind) => (
        <div
          key={kind}
          role={kind === 'alert' ? 'alert' : 'status'}
          className={cn(
            'flex items-start gap-3 rounded-lg border px-4 py-3 text-sm',
            kind === 'alert'
              ? 'border-destructive/30 bg-destructive/10 text-destructive'
              : 'border-primary/30 bg-primary/10',
          )}
        >
          <p className="flex-1">{flash[kind]}</p>
          <button
            type="button"
            onClick={() => setFlash((prev) => ({ ...prev, [kind]: undefined }))}
            className="text-muted-foreground hover:text-foreground"
            aria-label="×"
          >
            <X className="size-4" aria-hidden />
          </button>
        </div>
      ))}
    </div>
  )
}
