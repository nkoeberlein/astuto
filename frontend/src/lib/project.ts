// Project identity (mirrors config/initializers/project.rb)
export const PROJECT_NAME = 'Astuto Evolution'
export const PROJECT_SHORT_NAME = 'Evo'
export const PROJECT_REPOSITORY_URL = 'https://github.com/nkoeberlein/astuto-evo'

// Path the v2 frontend is served under (SpaController, router basepath)
export const APP_BASEPATH = '/next'

// Documentation still lives in the archived upstream docs repository (config/initializers/project.rb)
export const PROJECT_DOCS_URL = 'https://github.com/astuto/astuto-docs'
export const projectDocsUrl = (path: string) => `${PROJECT_DOCS_URL}/blob/main/docs/${path}`
