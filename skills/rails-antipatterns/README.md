# Rails Antipatterns

Reference skills covering Rails antipatterns drawn from *Rails Antipatterns* (Pytel & Saleh) and the 37signals tradition (DHH, Jorge Manrubia). Each skill names one smell and points at the Rails-idiomatic fix.

These complement the positive references in [`skills/rails/`](../rails/README.md) — load an antipattern skill when you're reviewing or refactoring code that exhibits the smell.

## Models

- **[fat-model-god-object](./rails-antipattern-fat-model-god-object/SKILL.md)** — A model that knows everything; extract concerns, value objects, and POROs (not service objects).
- **[callback-hell](./rails-antipattern-callback-hell/SKILL.md)** — Side-effecting callbacks that fire on every save; prefer explicit methods or jobs.
- **[voyeuristic-model](./rails-antipattern-voyeuristic-model/SKILL.md)** — Law of Demeter violations: `user.profile.address.city`. Use `delegate` or move behavior.
- **[anemic-domain-model](./rails-antipattern-anemic-domain-model/SKILL.md)** — Models with no behavior, logic in services. Behavior belongs on the model.
- **[spaghetti-sql](./rails-antipattern-spaghetti-sql/SKILL.md)** — Raw SQL or queries leaking into controllers and views; encapsulate in scopes.

## Controllers / Routes

- **[fat-controller](./rails-antipattern-fat-controller/SKILL.md)** — Business logic in controllers; push to model or extract a new resource.
- **[non-restful-actions](./rails-antipattern-non-restful-actions/SKILL.md)** — Custom actions instead of introducing a new resource (e.g. `PostPublication`).
- **[homemade-keys-and-routes](./rails-antipattern-homemade-keys-and-routes/SKILL.md)** — Hand-rolled URL schemes that bypass resourceful routing.
- **[bloated-session](./rails-antipattern-bloated-session/SKILL.md)** — Stuffing objects/state into `session`; use `Current` and the database.

## Views / Helpers

- **[php-itis-views](./rails-antipattern-php-itis-views/SKILL.md)** — Logic in ERB; use helpers, partials, or model methods.
- **[n-plus-one-in-views](./rails-antipattern-n-plus-one-in-views/SKILL.md)** — Iteration triggering queries; `includes` and a `preloaded` scope.
- **[god-helper-module](./rails-antipattern-god-helper-module/SKILL.md)** — `ApplicationHelper` as a dumping ground; split or move to models.

## Architecture (DHH / 37signals lens)

- **[service-object-soup](./rails-antipattern-service-object-soup/SKILL.md)** — `app/services/*Service` everywhere; prefer concerns, POROs, command methods on models.
- **[premature-abstraction-and-di](./rails-antipattern-premature-abstraction-and-di/SKILL.md)** — Dependency injection / interfaces solely for testability; trust Rails.
- **[mock-heavy-tests](./rails-antipattern-mock-heavy-tests/SKILL.md)** — Stubbing collaborators instead of using fixtures + real objects.

## Database

- **[migration-smells](./rails-antipattern-migration-smells/SKILL.md)** — Irreversible migrations, data backfills mixed with schema, missing FK indexes.
