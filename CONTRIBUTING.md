# Contributing guidelines

Thanks for taking the time to contribute 😁

We would like the Astuto Evolution community to be a welcoming environment for both seasoned programmers and absolute beginners. The following guidelines should help you get started regardless of your skill level.

## How to contribute

There are many ways to contribute to Astuto, not just coding. In this section we list the most common ones:

- **Getting involved in the community**: we love to hear opinions about our product. Dropping a comment on an open issue or pull request is an easy yet impactful way to contribute.
- **Reporting bugs or proposing features**:  [open a new issue](https://github.com/nkoeberlein/astuto-evo/issues/new) on GitHub. Before posting, check if a similar issue has already been reported. Try to be concise but also unambiguous.
- **Translating Astuto into a new language**: we want Astuto to speak all languages and we need contributors to achieve this goal! See [Translations](#translations) below.
- **Coding**: [open a pull request](https://github.com/nkoeberlein/astuto-evo/pulls) with your bug fix or feature implementation. Before diving into coding, you may find [the coding and testing section](#coding-and-testing) useful.

If you still have any doubt, feel free to open an issue and ask! And remember: there are no stupid questions 😉

## Translations

Translations were managed on Crowdin by the original project. Until Astuto Evolution has its own translation platform, please open a pull request that changes the YAML files described below.

### Translations structure

Locales are stored in YAML files under `config/locales`. Translations are splitted in 3 files:

- `[lang].yml`: contains frontend translations
- `backend/backend.[lang].yml`: contains backend translations, e.g. mailers, error messages, entity names
- `devise/devise.[lang].yml`: contains translations for the authentication system (which is based on [Devise](https://github.com/heartcombo/devise) gem). Usually, this file is not manually translated, because ready-made translations are already available at [this page](https://github.com/heartcombo/devise/wiki/I18n).

## Coding and testing

### Installation instructions for contributors

In order to contribute to Astuto, you need to run Astuto on your computer in development mode. In order to do so, please follow these instructions:

0. Ensure you have Docker and Docker Compose installed
1. Clone this repository
2. Edit `docker-compose.yml` if you want to change the value of some environment variables. Note that this `docker-compose.yml` is already configured to run Astuto in development mode (`target: dev`).
3. Run `docker compose build`
4. Run `docker compose up`
5. You should now have a running instance of Astuto at `localhost:3000`. A default user account has been created with credentials email: `admin@example.com`, password: `password`.

### Technologies

Depending on the task you're working on, you need to know one or more of these technologies:

- [Ruby on Rails](https://rubyonrails.org/): Ruby framework for the backend
- [React](https://reactjs.org/): UI library used for most of the frontend views
- [Redux](https://redux.js.org/): state management library for React
- [TypeScript](https://www.typescriptlang.org/)

### Project structure

The project is broadly structured as follows:

- `app`
  - `models`: Rails ActiveRecord models. These models are mapped by ActiveRecord to database tables.
  - `controllers`: Rails controllers. Web requests will be handled here. Here you can query the database, return HTML/JSON, etc. We try to keep controllers as small as possible.
  - `views`: Rails views. Some of these views render HTML directly, whereas others render React components. Ideally, we'd like to move the entire frontend to React.
  - `javascript`
    - `actions`: Redux actions
    - `components`: React components
    - `containers`: React components that connect to Redux state. See [this article](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0) to learn more.
    - `reducers`: Redux reducers
    - `stylesheets`: all CSS files are stored here
  - `mailers`: mail templates that are sent to notify users
  - `workflows`: classes that contains some complex logic. Usually that logic was originally in a controller, but has been refactored and delegated to a workflow. In fact, workflows are usually called inside controllers.
  - `policies`: policies used by [Pundit](https://github.com/varvet/pundit) for resource authorization
- `config`
  - `locales`: locales files for internationalization. See [this section](#translations) for additional information.
  - `routes.rb`: backend routes, i.e. mapping requests to controller actions
- `db`
  - `migrate`: contains migration files
  - `schema.rb`: database schema
- `spec`: RSpec tests

### Rails console

If you need to work with the Rails console, just attach a shell to the `web` container. From there, type `rails c` to run the console. You may notice that every query you run (e.g. `Post.all`) fails with error `Current::MissingCurrentTenant (Current tenant is not set)`: that's because Astuto implements multi tenancy at the database level. In order to fix this error, supposing you're in single tenant mode, just run `Current.tenant = Tenant.first` as the first command inside the Rails console. After that, everything should work as expected.

### Specs (tests)

Tests are done using RSpec, a testing framework for Ruby on Rails:

- To execute all specs, run `rspec` inside the `web` container (`docker compose exec web bundle exec rspec`).
- Browser tests of the user interface are Playwright tests in `frontend/e2e`: start the app (`docker compose up`), then run `npm run e2e` in `frontend/` (see `frontend/README.md`).
