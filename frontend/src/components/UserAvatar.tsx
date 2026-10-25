import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { cn } from '@/lib/utils'

export function UserAvatar(props: { name: string; url: string; className?: string }) {
  return (
    <Avatar className={cn('size-7', props.className)}>
      <AvatarImage src={props.url} alt="" />
      <AvatarFallback>{props.name.slice(0, 1).toUpperCase()}</AvatarFallback>
    </Avatar>
  )
}
