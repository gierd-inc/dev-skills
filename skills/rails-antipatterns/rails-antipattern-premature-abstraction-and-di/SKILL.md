---
name: rails-antipattern-premature-abstraction-and-di
description: Use when code introduces interfaces, dependency injection, or hexagonal-style ports purely to make testing easier — without a real second implementation in sight. Counter to the 37signals "trust the framework" stance.
---

# Antipattern: Premature Abstraction & Dependency Injection

## The smell
- Constructors that take a `repo:`, `clock:`, `mailer:`, `gateway:` keyword for every collaborator
- Repository / gateway / port classes wrapping a single Active Record model 1:1
- Test setup full of `instance_double(...)` / `class_double(...)` for things Rails already mocks (mailers, jobs, time)
- Only one production implementation exists; the "second" implementation is always a test double

## Why it hurts
- Costs are real: extra files, extra wiring, harder onboarding
- Benefits are imaginary — the second adapter never arrives
- Tests exercise the seam, not the behavior
- DHH/Manrubia: Rails *is* the abstraction layer. Don't build a second one to test it

## The fix
- **Use Active Record directly** — fixtures + test DB cover the "mocking" need
- Use Rails test helpers — `travel_to`, `assert_emails`, `perform_enqueued_jobs`, `freeze_time`
- **Real objects in tests** (see [mock-heavy-tests](../rails-antipattern-mock-heavy-tests/SKILL.md))
- Defer the abstraction until you genuinely have two implementations. YAGNI applies hardest in Rails

## When it's actually fine
You actually have (or will have within this PR) a second adapter — Stripe vs. Braintree, S3 vs. GCS, real vs. fake clock that can't be `travel_to`'d. Then a thin wrapper is justified.

## See also
- [service-object-soup](../rails-antipattern-service-object-soup/SKILL.md)
- [mock-heavy-tests](../rails-antipattern-mock-heavy-tests/SKILL.md)
- [rails-testing](../../rails/rails-testing/SKILL.md)

See `references/examples.md` for code samples.
