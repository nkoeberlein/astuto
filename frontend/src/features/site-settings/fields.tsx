import { type ReactNode, useId } from 'react'
import { Checkbox } from '@/components/ui/checkbox'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

// Form building blocks of the settings pages: a titled card, and fields with label and help text

export function SettingsSection(props: { title: string; children: ReactNode }) {
  const id = useId()
  return (
    <section aria-labelledby={id} className="space-y-5 rounded-xl border bg-card p-5 shadow-2xs">
      <h2 id={id} className="text-base font-semibold">
        {props.title}
      </h2>
      {props.children}
    </section>
  )
}

function Help({ id, children }: { id: string; children: ReactNode }) {
  return (
    <p id={id} className="text-sm text-muted-foreground">
      {children}
    </p>
  )
}

export function TextField(props: {
  label: string
  value: string
  onChange: (value: string) => void
  help?: ReactNode
  type?: 'text' | 'url' | 'number' | 'password'
  placeholder?: string
  autoComplete?: string
}) {
  const id = useId()
  return (
    <div className="space-y-1.5">
      <Label htmlFor={id}>{props.label}</Label>
      <Input
        id={id}
        type={props.type ?? 'text'}
        value={props.value}
        placeholder={props.placeholder}
        autoComplete={props.autoComplete}
        onChange={(event) => props.onChange(event.target.value)}
        aria-describedby={props.help ? `${id}-help` : undefined}
      />
      {props.help && <Help id={`${id}-help`}>{props.help}</Help>}
    </div>
  )
}

export function SelectField<T extends string>(props: {
  label: string
  value: T
  options: { value: T; label: string }[]
  onChange: (value: T) => void
  help?: ReactNode
}) {
  const id = useId()
  return (
    <div className="space-y-1.5">
      <Label htmlFor={id}>{props.label}</Label>
      <Select value={props.value} onValueChange={(value) => props.onChange(value as T)}>
        <SelectTrigger
          id={id}
          className="w-full sm:w-80"
          aria-describedby={props.help ? `${id}-help` : undefined}
        >
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {props.options.map((option) => (
            <SelectItem key={option.value} value={option.value}>
              {option.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      {props.help && <Help id={`${id}-help`}>{props.help}</Help>}
    </div>
  )
}

export function CheckboxField(props: {
  label: string
  checked: boolean
  onChange: (checked: boolean) => void
  help?: ReactNode
}) {
  const id = useId()
  return (
    <div className="flex gap-3">
      <Checkbox
        id={id}
        checked={props.checked}
        onCheckedChange={(checked) => props.onChange(checked === true)}
        aria-describedby={props.help ? `${id}-help` : undefined}
        className="mt-0.5"
      />
      <div className="space-y-1">
        <Label htmlFor={id}>{props.label}</Label>
        {props.help && <Help id={`${id}-help`}>{props.help}</Help>}
      </div>
    </div>
  )
}
