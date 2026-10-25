// Tenant custom CSS goes into a <style> element. Writing every "<" as the CSS
// escape "\3c " (like custom_css_for_style_tag in Rails) means "</style" can
// never appear, also once pages are rendered on the server (v3). Inside CSS
// strings the escape still stands for "<".
export function escapeCustomCss(css: string): string {
  return css.replace(/</g, '\\3c ')
}
