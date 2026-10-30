# Project identity: name and public links in one place.
# Astuto Evolution is the community continuation of astuto/astuto (archived in 2026).
module AstutoProject
  NAME = 'Astuto Evolution'
  # Release version (SemVer); keep in sync with frontend/package.json and CHANGELOG.md
  VERSION = '2.0.0-beta.1'
  SHORT_NAME = 'Evo'
  REPOSITORY_URL = 'https://github.com/nkoeberlein/astuto-evo'
  ISSUES_URL = "#{REPOSITORY_URL}/issues"
  UPSTREAM_URL = 'https://github.com/astuto/astuto'
  # Guides in docs/ of this repository (the upstream astuto-docs repository has no license, so
  # its text is not copied; docs/ covers the same topics)
  DOCS_URL = "#{REPOSITORY_URL}/blob/main/docs"
end
