// Plain text for lists and previews: Markdown syntax removed, cut after `max` characters
export function excerpt(markdown: string | null, max = 200): string {
  const text = (markdown ?? '')
    // Links and images keep only their text
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
    // Headings, quotes and list markers at the start of a line
    .replace(/^\s{0,3}(#{1,6}|>|[-*+]|\d+\.)\s+/gm, '')
    .replace(/[*_`~]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  return text.length > max ? `${text.slice(0, max).trimEnd()}…` : text
}
