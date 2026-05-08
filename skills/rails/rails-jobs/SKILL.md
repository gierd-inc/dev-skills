---
name: rails-jobs
description: use when writing Active Job background jobs, SolidQueue, retry/discard behavior
---

# Rails Jobs

## Job Configuration

- All jobs inherit from `ApplicationJob`
- Define `queue_as` at the top of the class; use `:default`, `:low`, or `:critical`
- Use Solid Queue in production (the Rails 8 default DB-backed runner; uses `FOR UPDATE SKIP LOCKED`)
- Prefer `perform_later` over `perform_now` for background execution
- For bulk enqueue, use `ActiveJob.perform_all_later(job1, job2, ...)` — single round-trip, no per-job callbacks
- For long-running, restart-safe work, use `ActiveJob::Continuable` with named `step` blocks (Rails 8.1+)

## Transactional Enqueue

- Active Job defers enqueue until after the surrounding transaction commits (default since 7.2) — do **not** wrap `perform_later` in `after_commit` callbacks
- The per-job `enqueue_after_transaction_commit` override is deprecated in 8.0; rely on the default
- For ad-hoc post-commit work, use `transaction do |t| t.after_commit { ... } end` or `ActiveRecord.after_all_transactions_commit { ... }`

## Retry and Failure Handling

- Use `retry_on` for transient, recoverable failures (e.g., network timeouts)
- Use `discard_on` for non-recoverable or known permanent errors (e.g., validation failures)
- Never silently swallow errors — log or notify on discard

## Inline vs Queued Execution

- Use `perform_now` only in tests or immediate preview contexts
- In controllers and mailers, always use `perform_later` or `deliver_later`
- Never use `deliver_now` in production code

See `references/examples.md` for code samples.
