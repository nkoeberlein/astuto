// Project identity (mirrors config/initializers/project.rb)
export const PROJECT_NAME = 'Astuto Evolution'
export const PROJECT_SHORT_NAME = 'Evo'
export const PROJECT_REPOSITORY_URL = 'https://github.com/nkoeberlein/astuto-evo'

// Path the pages are served under (SpaController, router basepath). Since 2.0 the frontend owns
// the root; only its built files stay under /next/assets (vite.config.ts `base`).
export const APP_BASEPATH = ''

// Guides in docs/ of this repository (config/initializers/project.rb)
export const PROJECT_DOCS_URL = `${PROJECT_REPOSITORY_URL}/blob/main/docs`
export const projectDocsUrl = (path: string) => `${PROJECT_DOCS_URL}/${path}`
