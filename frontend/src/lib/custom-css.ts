// Tenant custom CSS goes into a <style> element. Writing every "<" as the CSS
// escape "\3c " means "</style" can never appear, also once pages are rendered
// on the server (v3). Inside CSS strings the escape still stands for "<".
export function escapeCustomCss(css: string): string {
  return css.replace(/</g, '\\3c ')
}
