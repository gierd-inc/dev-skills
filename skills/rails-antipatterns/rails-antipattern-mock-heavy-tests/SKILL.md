---
name: rails-antipattern-mock-heavy-tests
description: Use when tests rely on `mock(...)`, `stub(...)`, or `expect(...).to receive(...)` to fake out collaborators that could just be real objects backed by fixtures. The 37signals fixture-first stance.
---

# Antipattern: Mock-Heavy Tests

## The smell
- Tests with more `mock` / `stub` / `expect(...).to receive(...)` lines than assertions
- Models, mailers, and jobs all stubbed out — no real DB activity
- Tests that pass while production breaks (mock/reality drift)
- Refactors break unrelated tests because mocks know too much

## Why it hurts
- Tests describe collaboration mechanics, not behavior
- New devs can't read the test as a spec for the system
- Refactors break tests that have nothing to do with the refactor
- Hides design problems (anemic models, excessive DI)

## The fix
- **Fixture-first, real-object Minitest** — Gierd default
- Real models with fixtures; real database for unit + integration tests
- Use `assert_emails`, `assert_enqueued_jobs`, `travel_to` for side effects and time
- **Stub only at system boundaries** — external HTTP (VCR/WebMock), unmockable randomness
- If a test feels hard to write with real objects, fix the design, not the test

## When it's actually fine
- External HTTP services
- Genuinely expensive operations in unit tests
- Verifying that a third-party SDK was called when its effects can't be inspected

## See also
- [rails-testing](../../rails/rails-testing/SKILL.md)
- [premature-abstraction-and-di](../rails-antipattern-premature-abstraction-and-di/SKILL.md)

See `references/examples.md` for code samples.
