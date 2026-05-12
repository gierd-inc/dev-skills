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
- Rails testing reference: `../../rails/references/testing.md`
- [premature-abstraction-and-di](premature-abstraction-and-di.md)

## Examples

### The smell

```ruby
test "publishing a post notifies subscribers" do
  post       = mock("post", id: 1, subscribers: [mock("sub", email: "a@b.com")])
  mailer     = mock("mailer")
  job_class  = class_double(NotifySubscribersJob)
  publisher  = Publisher.new(mailer: mailer, job_class: job_class)

  mailer.expects(:notify).with(post)
  job_class.expects(:perform_later).with(post)

  publisher.call(post)
end
```

### The fix — fixture-first, real objects

```ruby
# test/models/post_test.rb
require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "publish marks the post as published and notifies subscribers" do
    post = posts(:draft)

    assert_emails 1 do
      assert_enqueued_with(job: NotifySubscribersJob, args: [post]) do
        post.publish
      end
    end

    assert post.published?
    assert_not_nil post.published_at
  end
end
```

### Stub only at the boundary

```ruby
class StripeWebhookTest < ActiveSupport::TestCase
  test "ignores untrusted signatures" do
    Stripe::Webhook.stub(:construct_event, ->(*) { raise Stripe::SignatureVerificationError }) do
      post stripe_webhooks_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "bad" }
      assert_response :bad_request
    end
  end
end
```

```ruby
# Time
test "trial expires after 30 days" do
  user = users(:trialing)
  travel_to user.trial_started_at + 31.days do
    assert user.trial_expired?
  end
end
```
