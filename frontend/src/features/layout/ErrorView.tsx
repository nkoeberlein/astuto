import { ApiError } from '@/api/client'
import { Button } from '@/components/ui/button'

// Shown when a route fails to load. Works without translations (they may be what failed).
export function ErrorView({ error }: { error: unknown }) {
  const status = error instanceof ApiError ? error.status : undefined
  const message = error instanceof Error ? error.message : 'Unknown error'

  return (
    <div className="mx-auto max-w-md space-y-4 py-16 text-center">
      <p className="text-5xl font-semibold text-muted-foreground">{status ?? '!'}</p>
      <p>{message}</p>
      {status === 401 ? (
        <Button asChild>
          <a href="/users/sign_in">Log in</a>
        </Button>
      ) : (
        <Button variant="outline" onClick={() => window.location.reload()}>
          Reload
        </Button>
      )}
    </div>
  )
}
