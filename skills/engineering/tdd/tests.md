# Good and Bad Tests

Examples are Minitest with Rails fixtures (Gierd's stack). Same principles apply to RSpec or Test::Unit; only the syntax differs.

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```ruby
# GOOD: Tests observable behavior
class CheckoutTest < ActiveSupport::TestCase
  test "user can checkout with valid cart" do
    cart = Cart.create!(user: users(:alice))
    cart.add(products(:widget))

    result = Checkout.new(cart, payment_methods(:alice_card)).call

    assert_equal "confirmed", result.status
  end
end
```

Characteristics:

- Tests behavior callers care about
- Uses public API only (calling `Checkout.new(...).call`, not internal methods)
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```ruby
# BAD: Tests implementation details
class CheckoutTest < ActiveSupport::TestCase
  test "checkout calls PaymentService#process" do
    mock_payment = Minitest::Mock.new
    mock_payment.expect(:process, true, [cart.total])

    PaymentService.stub(:new, mock_payment) do
      Checkout.new(cart, payment).call
    end

    mock_payment.verify
  end
end
```

Red flags:

- Mocking internal collaborators (`PaymentService.stub`, `Minitest::Mock`)
- Testing private methods (`send(:internal_method)`)
- Asserting on call counts / argument order via `expect(...).to have_received`
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means (raw SQL) instead of through the interface

```ruby
# BAD: Bypasses interface to verify
test "create_user saves to database" do
  Users::Create.new(name: "Alice").call

  row = ActiveRecord::Base.connection.execute(
    "SELECT * FROM users WHERE name = 'Alice'"
  ).first

  assert_not_nil row
end

# GOOD: Verifies through interface
test "create_user makes user retrievable" do
  user = Users::Create.new(name: "Alice").call

  retrieved = User.find(user.id)
  assert_equal "Alice", retrieved.name
end
```

## A note on fixtures vs. factories

Gierd uses **Rails fixtures** (not FactoryBot). Fixtures load once per suite and stay consistent across tests, which is fast and predictable. When a test needs a one-off variation, build it inline from a fixture as a starting point:

```ruby
test "discount applies to high-value carts" do
  cart = carts(:alice_empty)
  cart.add(products(:premium_widget), quantity: 50)  # tweak inline

  assert cart.eligible_for_discount?
end
```

Don't reach for FactoryBot or transactional helpers from other ecosystems unless the test genuinely cannot be expressed against a fixture.

## System tests

For end-to-end browser tests, use Rails system tests (`ActionDispatch::SystemTestCase`) with Capybara. These are the equivalent of "integration-style" at the highest level: they exercise routing, controllers, views, JS, and the database together. Reserve them for golden paths — they're slow.
