// Project identity: name and public links in one place (mirrors config/initializers/project.rb)
export const PROJECT_NAME = 'Astuto Evolution';
export const PROJECT_SHORT_NAME = 'Evo';
export const PROJECT_REPOSITORY_URL = 'https://github.com/nkoeberlein/astuto';
export const PROJECT_ISSUES_URL = `${PROJECT_REPOSITORY_URL}/issues`;

// Documentation still lives in the archived upstream docs repository
export const PROJECT_DOCS_URL = 'https://github.com/astuto/astuto-docs';
export const projectDocsUrl = (path: string) => `${PROJECT_DOCS_URL}/blob/main/docs/${path}`;
