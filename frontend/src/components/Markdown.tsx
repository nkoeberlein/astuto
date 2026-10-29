import ReactMarkdown from 'react-markdown'

// Renders user-written Markdown. Raw HTML is ignored.
export function Markdown({ children }: { children: string }) {
  return (
    <div className="space-y-3 break-words text-sm leading-relaxed [&_a]:text-primary [&_a]:underline [&_code]:rounded [&_code]:bg-muted [&_code]:px-1 [&_ol]:list-decimal [&_ol]:ps-5 [&_ul]:list-disc [&_ul]:ps-5">
      <ReactMarkdown skipHtml>{children}</ReactMarkdown>
    </div>
  )
}
