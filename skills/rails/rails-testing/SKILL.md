---
name: rails-testing
description: use when writing Rails tests with Minitest and fixtures (model, controller, system, integration tests)
---

# Rails Testing

This codebase uses Minitest with fixtures exclusively. Do NOT use RSpec or FactoryBot.

## Core Principles

- Each test file must match the class/module under test
- Prefer built-in assertions: `assert_difference`, `assert_changes`, `assert_predicate`, `assert_includes`, `assert_no_difference`
- Use descriptive test names: `test "admin can view dashboard"`
- Avoid mocks/stubs — prefer real Rails behavior end-to-end
- Keep tests fast and deterministic

## Model Tests

- Place in `test/models/`, use `ActiveSupport::TestCase`
- Test validations, associations, scopes, callbacks, and business logic
- Reference fixtures by label: `users(:john)`

## Controller Tests

- Place in `test/controllers/`, use `ActionDispatch::IntegrationTest`
- Test RESTful actions, authentication, and Turbo Stream responses
- Assert redirects, flash messages, response status, and DOM structure

## Job Tests

- Place in `test/jobs/`, use `ActiveJob::TestCase`
- Assert enqueued and performed jobs with `assert_enqueued_with` / `assert_performed_with`

## Mailer Tests

- Place in `test/mailers/` and `test/mailers/previews/`, use `ActionMailer::TestCase`
- Assert subject, to/from, and body content
- Use `assert_emails` to assert delivery count

## Helper Tests

- Place in `test/helpers/`, use `ActionView::TestCase`
- Test custom view helpers in isolation

## Route Assertions

- Place inside controller or integration tests
- Use `assert_routing` and `assert_recognizes` for custom constraints

## Fixtures

- Store in `test/fixtures/<table>.yml`
- Reference associations by fixture label (not id)
- Use realistic, minimal data with proper associations

## Key Assertion Patterns

- `assert_difference "Model.count", +1 do ... end`
- `assert_no_difference "Model.count" do ... end`
- `assert_changes -> { record.reload.attr }, from: x, to: y do ... end`
- `assert_enqueued_with(job: MyJob, args: [...]) do ... end`
- `assert_emails 1 do ... end`
- `assert_raises ExceptionClass do ... end`

See `references/examples.md` for code samples.
