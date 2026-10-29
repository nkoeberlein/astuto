import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { cn } from '@/lib/utils'

// Gravatar picture, or the initial when there is none (Gravatar switched off in the settings)
export function UserAvatar(props: { name: string; url: string | null; className?: string }) {
  return (
    <Avatar className={cn('size-7', props.className)}>
      {props.url && <AvatarImage src={props.url} alt="" />}
      <AvatarFallback>{props.name.slice(0, 1).toUpperCase()}</AvatarFallback>
    </Avatar>
  )
}
