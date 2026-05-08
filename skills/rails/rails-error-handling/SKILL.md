---
name: rails-error-handling
description: "use when handling Rails validation errors, exceptions, custom error pages, error reporting (Rails.error/Honeybadger/etc), tagged logging, or debugging Rails issues with debug gem/console/logging"
---

# Rails Error Handling

## Validation Errors

- Use `errors.add(:field, "message")` to attach custom messages in validations
- Use `errors.full_messages` for user display; `errors.details` for API/machine-readable output
- Prefer `ActiveModel::Validator` or `validate :method_name` over inline logic
- Always write clear, user-friendly validation messages

## Exceptions & Rescue

- Never rescue generic `StandardError` unless you re-raise it
- Use `rescue_from` in `ApplicationController` for domain-specific errors (e.g., `ActiveRecord::RecordNotFound`)
- Raise custom exceptions as subclasses of `StandardError`; include context and error codes
- Custom error hierarchy: `ApplicationError < StandardError`, then `AuthenticationError`, `AuthorizationError`, `ValidationError`, `ExternalServiceError`
- Avoid silent failures — always log unexpected exceptions with context
- Set the correct HTTP status code whenever you render an error response

## Custom Error Pages

- Route exceptions through a custom controller: `config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }`
- Create `ErrorsController#show` that renders `404`, `422`, `500` views by status code
- Use semantic, user-friendly copy in error views

## Error Reporting & Monitoring

- Prefer the Rails-native error reporter over vendor SDKs for new code:
  - `Rails.error.report(e)` — report an already-caught exception
  - `Rails.error.handle { ... }` — report and swallow (returns `nil` on error)
  - `Rails.error.record { ... }` — report and re-raise
  - All accept `context:`, `severity:` (`:error|:warning|:info`), `handled:`, `source:`
- Do **not** add new `Honeybadger.notify` calls — replace with `Rails.error.*`. Existing Honeybadger config may stay until migration completes.
- Use `Rails.error.handle(fallback: -> { default })` for graceful failures in models/domain code
- Use `Rails.error.handle` with tag/context blocks in background jobs; always re-raise after tagging
- For Honeybadger (legacy): use `before_notify` to filter routing errors and add custom context (hostname, commit SHA)
- For Sentry: configure `before_send` to filter sensitive params and fingerprint `ApplicationError` by class + error code
- Implement circuit breakers for external service calls; return cached fallback on open circuit
- Add health check endpoints (`/health`) that test database, Redis, and external APIs; return 503 on failure

## Logging

- Use tagged logging for request context: `Rails.logger.tagged("User: #{id}") { ... }`
- Configure global log tags in `production.rb`: `config.log_tags = [:request_id, ...]`
- Use `Rails.logger.with_context(...)` in `around_action` to attach request/user context to all logs
- Log at structured JSON for searchability; include `event`, `error_class`, `order_id`, timestamps, etc.
- Log slow operations (>100ms) with SQL, duration, and caller backtrace
- Log job lifecycle: started, completed, failed — include duration and memory delta

## Debugging

- Add `debugger` or `binding.break` for interactive breakpoints (requires `gem "debug"`)
- Use conditional breakpoints: `debugger if order.total > 1000`
- In Rails console: `reload!`, `app.get '/path'`, `User.joins(:posts).explain`, `Benchmark.ms { ... }`
- Use `ActiveRecord::Base.logger = Logger.new(STDOUT)` to log SQL in console sessions
- Use `QueryDebugger.find_n_plus_one_queries { ... }` to detect N+1 patterns via Notifications
- In production: gate debugging behind `ENV["DEBUG_FEATURE"]` or feature flags; use read-only queries only
- Use `relation.explain` and `EXPLAIN ANALYZE` to inspect query plans

See `references/examples.md` for code samples.
