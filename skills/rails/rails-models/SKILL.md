---
name: rails-models
description: Use when working with Active Record models, associations, validations, scopes, callbacks, enums, or model concerns.
---

# Rails Models

## Structure & Naming
- One model per file; file name must match class name (`post.rb` → `class Post`)
- Use Zeitwerk-compatible naming
- Inherit from `ApplicationRecord`
- Keep models focused on data structure, relationships, and business logic
- Prefer validations and scopes over callbacks when possible

## Associations
- Use `dependent: :destroy` when appropriate
- Use `inverse_of` to optimize object identity and performance
- Use `optional: true` for nullable foreign keys
- Prefer `has_many :through` over `has_and_belongs_to_many`
- Index foreign keys in migrations
- Use `default: -> { Current.user }` for automatic user assignment

## Validations (Business Rules)
- Validations encode business rules — define what valid data looks like
- Prefer model-level validations over form-level logic
- Add database-level constraints for uniqueness where critical
- Use `validates_with` or custom validators for complex logic
- Combine with `with_options` to DRY up repetitive declarations

## Scopes
- Use `scope` for composable query logic
- Chain scopes where possible: `.published.recent.limit(10)`
- Use class methods for complex queries that don't chain well
- Name scopes with adverbs/business terms, not SQL-ish: `chronologically`, `reverse_chronologically`, `latest`, `alphabetically`, `active`, `unassigned`
- Use `preloaded` as the standard name for the eager-loading scope
- Parameterized scope names: `indexed_by(...)`, `sorted_by(...)`

## Method Naming
- Action methods are verbs: `card.close`, `card.gild`, `board.publish` (avoid `set_*` setters)
- Predicates derive from state: `card.closed?`, `card.golden?` — prefer presence-of-related-record over boolean columns
- Concerns are adjectives describing capability: `Closeable`, `Publishable`, `Watchable`

## State as Records (over boolean columns)
- Track state by the presence of a related record, not a boolean column. Lets state carry timestamps, actors, and metadata for free.
- Query with associations: `Card.joins(:closure)` for closed; `Card.where.missing(:closure)` for open

## Callbacks
- Keep callbacks short, testable, and idempotent
- Prefer `after_commit` for side-effects that rely on a successful save
- Do not chain multiple callbacks for business logic
- Extract complex logic to a concern or domain model in `app/models/domain/`

## Attributes (Rails Edge)

### Data Normalization
- Use `normalizes` for automatic data cleaning: `normalizes :email, with: ->(e) { e.strip.downcase }`

### Enums
- Use `enum :status, { draft: 0, published: 1 }, suffix: true, scopes: false`
- `suffix: true` creates readable methods: `post.draft_status?`, `post.published_status?`
- Avoid changing enum values once deployed

### Encrypted Attributes
- Use `encrypts :field_name` for sensitive data
- Avoid encrypting fields that need to be queried or indexed

### Rich Text & Attachments
- Use `has_rich_text :content` for Action Text
- Use `has_many_attached :images` for Active Storage

## Real-Time Updates (Rails Edge)
- Prefer `broadcasts_refreshes` for automatic Turbo Morph updates
- Use `broadcasts_to` for more granular control
- Only broadcast from models that affect visible UI
- Use `broadcast_replace_later_to` when updates should be async

## Code Organization (Service Objects as Last Resort)
- Extract reusable logic into `app/models/concerns/` using `ActiveSupport::Concern`
- For complex workflows, use domain models in `app/models/domain/`
- Prefer form objects, query objects, and rich domain models over service objects
- Service objects may be legitimate (multi-model workflows, external API integration) but be prepared to justify a new one; existing service object patterns are accepted

## Rails Idioms
- Use `delegate` for clean model interfaces
- Use `with_options` to DRY up repetitive declarations
- Use `presence` over `blank?` checks with `||`
- Use safe navigation (`&.`) to avoid nil errors

## Authentication & Security
- Use `has_secure_password` for password hashing
- Use `has_secure_token :auth_token` for API tokens
- Validate `password` with `presence: true, on: :create`
- Do not store plaintext or reversible tokens

## Method Organization
- Public methods first, then `private` section
- Group related methods with blank lines between groups
- Keep methods short (5-15 lines ideal)
- Use descriptive names that explain intent

See `references/examples.md` for code samples.
