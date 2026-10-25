import { PROJECT_SHORT_NAME } from '@/lib/project'
import { cn } from '@/lib/utils'

export function EvoLogo({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 256 256"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={cn('size-8 shrink-0', className)}
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="evo-bg" x1="0" y1="0" x2="256" y2="256" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#FFF7ED" />
          <stop offset="100%" stopColor="#FFEDD5" />
        </linearGradient>
        <linearGradient
          id="evo-amber"
          x1="32"
          y1="20"
          x2="224"
          y2="236"
          gradientUnits="userSpaceOnUse"
        >
          <stop offset="0%" stopColor="#FB923C" />
          <stop offset="50%" stopColor="#F97316" />
          <stop offset="100%" stopColor="#EA580C" />
        </linearGradient>
      </defs>
      <rect
        x="12"
        y="12"
        width="232"
        height="232"
        rx="56"
        fill="url(#evo-bg)"
        stroke="url(#evo-amber)"
        strokeWidth="8"
      />
      <polygon points="44,34 104,68 62,102" fill="url(#evo-amber)" />
      <polygon points="212,34 152,68 194,102" fill="url(#evo-amber)" />
      <path
        d="M 40 90 C 36 62, 38 38, 42 26 C 64 38, 86 52, 104 60 C 120 56, 136 56, 152 60 C 170 52, 192 38, 214 26 C 218 38, 220 62, 216 90"
        stroke="#0F172A"
        strokeWidth="16"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M 52 88 C 36 116, 32 138, 30 156 C 68 160, 94 180, 102 212 C 106 224, 116 230, 128 230 C 140 230, 150 224, 154 212 C 162 180, 188 160, 226 156 C 224 138, 220 116, 204 88"
        stroke="#0F172A"
        strokeWidth="16"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M 32 136 C 78 142, 106 168, 114 206"
        stroke="#0F172A"
        strokeWidth="14"
        strokeLinecap="round"
      />
      <path
        d="M 224 136 C 178 142, 150 168, 142 206"
        stroke="#0F172A"
        strokeWidth="14"
        strokeLinecap="round"
      />
      <polygon points="96,116 110,130 96,144 82,130" fill="#0F172A" />
      <polygon points="160,116 174,130 160,144 146,130" fill="url(#evo-amber)" />
      <line
        x1="118"
        y1="204"
        x2="138"
        y2="204"
        stroke="#0F172A"
        strokeWidth="14"
        strokeLinecap="round"
      />
    </svg>
  )
}

export function EvoBadge({ className }: { className?: string }) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full bg-linear-to-r from-orange-500 to-amber-600 px-2 py-0.5 text-[10px] font-extrabold tracking-wider text-white uppercase shadow-xs',
        className,
      )}
    >
      {PROJECT_SHORT_NAME}
    </span>
  )
}
