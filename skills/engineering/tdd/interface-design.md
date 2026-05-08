# Interface Design for Testability

Good interfaces make testing natural. Examples in Ruby; same principles apply to any OO language.

## 1. Accept dependencies, don't create them

```ruby
# Testable: gateway passed in
class ProcessOrder
  def initialize(order, payment_gateway: Stripe::Gateway.new)
    @order = order
    @payment_gateway = payment_gateway
  end

  def call
    @payment_gateway.charge(@order.total)
  end
end
```

```ruby
# Hard to test: gateway hard-wired inside
class ProcessOrder
  def call
    Stripe::Gateway.new.charge(@order.total)
  end
end
```

In Rails, the canonical pattern is a **service object** (a PORO under `app/services/` with a single `#call` method) that takes its collaborators in `initialize`. Active Record models can do the same — pass a logger, a clock, or a notifier rather than calling `Rails.logger.info` and `Time.current` inline.

## 2. Return results, don't mutate hidden state

```ruby
# Testable: pure computation
class CalculateDiscount
  def call(cart) = Discount.new(...)
end

# Hard to test: side-effecting setter
class ApplyDiscount
  def call(cart)
    cart.total -= discount  # caller has to inspect cart afterward
    nil
  end
end
```

A test for the testable version asserts on the return value. A test for the side-effecting version has to set up `cart`, run the call, then re-fetch and assert on `cart.total` — and it can't tell whether other side effects also happened.

## 3. Small surface area

- Fewer public methods = fewer tests needed.
- Fewer initializer params = simpler test setup. If you find yourself passing 6 collaborators, the object is doing too much; split it.
- Prefer one entry point (`#call`, `#perform`, `#process`) over a class with `#step1`, `#step2`, `#step3`.

## 4. Make state retrievable through the interface

Tests should be able to verify behavior by *calling the same code production calls*. If the only way to confirm "the user was created" is to query the database or peek at instance variables, the interface is missing a getter (e.g., `User.find(id)` exposed via the public model interface). See [tests.md](tests.md) for the "verify through interface" example.

## 5. Active Record gotchas

- Avoid `before_save`/`after_create` callbacks that perform external I/O — they make every test that touches the model implicitly depend on that I/O. Move side effects into an explicit service or job, called from the controller.
- Prefer `dependent: :destroy` over manual cleanup in callbacks.
- For tests of model logic, use unit-style tests with fixtures; for tests of controller→model→DB flow, use integration tests.
