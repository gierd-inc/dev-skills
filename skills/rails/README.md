# Rails Skills

Domain references for Rails 8.1+ work. Each skill is loaded on-demand based on what the agent is touching — you don't need to pull them all into context up front. Skill descriptions advertise their trigger conditions.

These come from [agency-plugin](https://github.com/ryenski/agency-plugin) and are tuned for Gierd's stack: Rails 8.1+, Hotwire (Turbo + Stimulus), Tailwind, Minitest with fixtures, Solid Queue / Solid Cache / Solid Cable, Kamal 2 deployment.

## Layered references

- **[rails-the-rails-way](./rails-the-rails-way/SKILL.md)** — General conventions, project style, code organization, philosophy.
- **[rails-models](./rails-models/SKILL.md)** — Active Record models, associations, validations, scopes, callbacks, enums, concerns.
- **[rails-controllers](./rails-controllers/SKILL.md)** — RESTful actions, strong params, before_actions, respond_to, Turbo streams, controller concerns.
- **[rails-routes](./rails-routes/SKILL.md)** — Resourceful routes, constraints, namespacing, `config/routes.rb`.
- **[rails-views](./rails-views/SKILL.md)** — ERB templates, forms, layout components (incl. Gierd's `g_*` design system helpers).
- **[rails-helpers](./rails-helpers/SKILL.md)** — View helpers, presentation logic in `app/helpers/`.
- **[rails-hotwire-frontend](./rails-hotwire-frontend/SKILL.md)** — Turbo (Streams/Frames/Morph), Stimulus, Tailwind.
- **[rails-jobs](./rails-jobs/SKILL.md)** — Active Job, Solid Queue, retry/discard.
- **[rails-mailers](./rails-mailers/SKILL.md)** — Action Mailer classes, mail views, deliveries.
- **[rails-mailbox](./rails-mailbox/SKILL.md)** — Action Mailbox inbound email routing.
- **[rails-action-cable](./rails-action-cable/SKILL.md)** — WebSocket channels, subscriptions, broadcasts.
- **[rails-action-text](./rails-action-text/SKILL.md)** — Rich content, trix editor, `has_rich_text`.
- **[rails-active-storage](./rails-active-storage/SKILL.md)** — File attachments, variants, direct uploads.
- **[rails-active-support](./rails-active-support/SKILL.md)** — Helpers, concerns, time zones, core extensions.
- **[rails-migrations](./rails-migrations/SKILL.md)** — Active Record migrations, schema changes, indexes.
- **[rails-composite-keys](./rails-composite-keys/SKILL.md)** — Composite primary keys.
- **[rails-autoloading](./rails-autoloading/SKILL.md)** — Zeitwerk, constant resolution, file naming, eager loading.
- **[rails-error-handling](./rails-error-handling/SKILL.md)** — Validation errors, exceptions, error pages, error reporting (Rails.error / Honeybadger), tagged logging, debugging.
- **[rails-security](./rails-security/SKILL.md)** — Authentication (Rails 8 `has_secure_password`), authorization, CSRF, security headers.
- **[rails-localization](./rails-localization/SKILL.md)** — I18n translations, locale files, pluralization, time/number formatting.
- **[rails-performance-and-caching](./rails-performance-and-caching/SKILL.md)** — Query optimization (N+1, includes/eager_load), HTTP caching, Russian-doll fragment caching, Solid Cache, app server tuning.
- **[rails-testing](./rails-testing/SKILL.md)** — Minitest with fixtures (model, controller, system, integration tests).
- **[rails-deployment](./rails-deployment/SKILL.md)** — Kamal deployment, Dockerfile, production environment, `deploy.yml`.
