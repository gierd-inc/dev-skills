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

## Instrumentation

- Use `ActiveSupport::Notifications.instrument("group.event")` for observability
- Name events with dot notation and avoid generic terms
- Subscribe using `ActiveSupport::Notifications.subscribe("event.name")`
- Ensure payloads are JSON-serializable; avoid leaking sensitive data
- Only instrument where observability is genuinely valuable

See `references/examples.md` for code samples.
