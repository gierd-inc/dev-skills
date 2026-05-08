# OOP Patterns for Rails

Design patterns for when Rails' defaults stop being enough. Each skill in this bucket documents one extraction pattern — what it is, when to reach for it, and how it looks in idiomatic Rails 8.1+ / Minitest / Hotwire code.

**The default is still the Rails Way.** Fat models, thin controllers, and concerns cover 80% of cases. These patterns are tools in the toolbox, not a default architecture. Every skill here explicitly states when *not* to use it — start with [rails-the-rails-way](../rails/rails-the-rails-way/SKILL.md) and [rails-models](../rails/rails-models/SKILL.md), then come here when complexity earns the extra layer.

See also [rails-antipatterns/](../rails-antipatterns/README.md) for the anti-patterns these can both solve and create when misapplied.

## Patterns

- **[oop-value-objects](./oop-value-objects/SKILL.md)** — Immutable domain values with equality by content: `Money`, `EmailAddress`, `DateRange`. Composed into AR via `composed_of` or custom attribute types.
- **[oop-null-objects](./oop-null-objects/SKILL.md)** — Replace `nil` with a stand-in that honors the full interface: `GuestUser`, `NullSubscription`. Eliminates defensive `&.` and `if x.present?` guards at call sites.
- **[oop-concerns-and-mixins](./oop-concerns-and-mixins/SKILL.md)** — `ActiveSupport::Concern` for shared behavior across 2+ models: `Publishable`, `Archivable`, `Auditable`. The Rails-idiomatic alternative to deep inheritance.
- **[oop-presenters](./oop-presenters/SKILL.md)** — View-layer wrappers (`SimpleDelegator` or plain Ruby) that add display logic — labels, CSS classes, formatted strings — without touching the model.
- **[oop-query-objects](./oop-query-objects/SKILL.md)** — Encapsulate complex AR queries that outgrow scopes: multi-join reports, filter+sort+paginate pipelines. Always return `ActiveRecord::Relation` to stay composable.
- **[oop-form-objects](./oop-form-objects/SKILL.md)** — `ActiveModel::Model` classes for multi-model forms, virtual attributes, and context-specific validations that don't belong on the model itself.
- **[oop-service-objects](./oop-service-objects/SKILL.md)** — Last-resort POROs for operations that genuinely cross aggregate boundaries (multi-model transactions, external API integrations). Named as domain nouns, not `*Service`.
- **[oop-policy-objects](./oop-policy-objects/SKILL.md)** — Per-resource authorization: one class per resource, one method per action (`show?`, `edit?`, `destroy?`). Works standalone or with Pundit.
- **[oop-repository-pattern](./oop-repository-pattern/SKILL.md)** — Rarely needed in Rails. A seam between domain objects and persistence — justified only when swapping data sources or needing strict in-memory test isolation. ActiveRecord IS the default repository.
