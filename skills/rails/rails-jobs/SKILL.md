---
name: rails-jobs
description: use when writing Active Job background jobs, SolidQueue, retry/discard behavior
---

# Rails Jobs

## Job Configuration

- All jobs inherit from `ApplicationJob`
- Define `queue_as` at the top of the class; use `:default`, `:low`, or `:critical`
- Use SolidQueue in production for background job processing
- Prefer `perform_later` over `perform_now` for background execution

## Retry and Failure Handling

- Use `retry_on` for transient, recoverable failures (e.g., network timeouts)
- Use `discard_on` for non-recoverable or known permanent errors (e.g., validation failures)
- Never silently swallow errors — log or notify on discard

## Inline vs Queued Execution

- Use `perform_now` only in tests or immediate preview contexts
- In controllers and mailers, always use `perform_later` or `deliver_later`
- Never use `deliver_now` in production code

See `references/examples.md` for code samples.
