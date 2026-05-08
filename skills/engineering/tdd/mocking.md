# When to Mock

Mock at **system boundaries** only:

- External APIs (Stripe, Amazon SP-API, eBay, sendgrid, etc.)
- Time/randomness (`Time.zone.now`, `SecureRandom`)
- File system / Active Storage uploads
- Background job side effects (use `assert_enqueued_with` instead of mocking the job class)

Don't mock:

- Your own service objects, models, or controllers
- Anything you control
- The database — Gierd uses Rails fixtures + transactional tests; that's fast enough and far more honest than DB mocks. (See [tests.md](tests.md) for the fixture stance.)

## Tools available in Minitest

- `Minitest::Mock` — strict mock with expectation verification (`mock.expect(:method, return_value, [args]); mock.verify`)
- `Object#stub` (Minitest) — temporarily stub a method on an instance for the duration of a block
- `ActiveSupport::Testing::TimeHelpers` — `freeze_time`, `travel_to`, `travel_back`. Always prefer these over stubbing `Time.current`.
- `WebMock` / `VCR` — for HTTP boundaries. Default to `WebMock.disable_net_connect!` in test setup; record cassettes with VCR for replay.
- `assert_enqueued_with` / `assert_performed_with` — for Active Job boundaries.

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

### 1. Use dependency injection

Pass external clients in rather than instantiating them internally:

```ruby
# Easy to mock
class ProcessPayment
  def initialize(order, payment_client: Stripe::Client.new)
    @order = order
    @payment_client = payment_client
  end

  def call
    @payment_client.charge(@order.total)
  end
end

# In a test:
ProcessPayment.new(order, payment_client: fake_client).call
```

```ruby
# Hard to mock
class ProcessPayment
  def call
    Stripe::Client.new(ENV["STRIPE_KEY"]).charge(@order.total)
  end
end
```

### 2. Prefer specific gateway methods over generic HTTP wrappers

Create one method per external operation instead of one `request(:get, path, params)` that branches inside.

```ruby
# GOOD: Each method is independently stubbable
class AmazonClient
  def get_orders(seller_id, since:); end
  def get_inventory(seller_id); end
  def create_listing(payload); end
end
```

```ruby
# BAD: Tests have to know which path/method to stub for which behavior
class AmazonClient
  def request(method, path, params = {}); end
end
```

The "specific method" approach means:

- Each stub returns one specific shape
- No conditional logic in test setup
- Easier to see at a glance which Amazon endpoints a test exercises
- Cassettes / WebMock stubs map cleanly to Ruby methods

### 3. Wrap clock and randomness behind helpers

Don't sprinkle `Time.zone.now` and `SecureRandom.uuid` through domain code — call a single helper (`Clock.now`, `Identifiers.next`) so tests can swap a deterministic implementation. Or use `freeze_time` for the whole test.
