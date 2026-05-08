---
name: rails-active-support
description: use when using Active Support helpers, concerns, time zones, core extensions
---

# Rails Active Support

## CurrentAttributes

- Use `Current` to store per-request data like user, account, or timezone
- Do not store mutable state across threads or background jobs
- Always reset `Current` at the beginning of a request
- Declare attributes with `attribute :user, :account` inside the class

## Core Extensions

- Prefer Rails-provided core extensions over monkey-patching
- Place any custom extensions under `config/initializers/core_ext/`
- Avoid reopening core classes in libraries or gems

## Concerns

- Use `ActiveSupport::Concern` to modularize cross-cutting behaviors
- Use `included do ... end` for class-level hooks
- Include concerns in models or controllers as needed

## Serialization (MessagePack)

- Prefer `ActiveSupport::MessagePack` over JSON/Marshal for cookies and cache: smaller, faster, supports Ruby types (Time, Symbol, BigDecimal)
- `config.active_support.message_serializer = :message_pack`
- `config.action_dispatch.cookies_serializer = :message_pack`
- `config.cache_store = :file_store, "tmp/cache", { serializer: :message_pack }`

## Deprecators Registry

- Register gem/engine deprecators with `Rails.application.deprecators[:my_gem] = ActiveSupport::Deprecation.new("2.0", "MyGem")`
- Lookup via `Rails.application.deprecators[:my_gem].warn(...)`
- `Rails.application.deprecators.silence { ... }` silences all registered deprecators at once

## Instrumentation

- Use `ActiveSupport::Notifications.instrument("group.event")` for observability
- Name events with dot notation and avoid generic terms
- Subscribe using `ActiveSupport::Notifications.subscribe("event.name")`
- Ensure payloads are JSON-serializable; avoid leaking sensitive data
- Only instrument where observability is genuinely valuable

See `references/examples.md` for code samples.
