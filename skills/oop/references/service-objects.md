# Service Objects

## What it is

A Service Object is a plain Ruby class that encapsulates one business operation. It has a single entry point (conventionally `call`), accepts input, performs the work, and returns a result. It's a fallback for operations that genuinely don't belong to any model — not a default architecture.

> **Warning:** Rails' own idiom (the DHH/37signals tradition) is to put behavior on models, not to extract it into services. An app full of `*Service` classes is the [anemic domain model antipattern](../../rails-antipatterns/rails-antipattern-anemic-domain-model/SKILL.md). Start there. Come back here when you've exhausted simpler options.

## Would a fat model / concern / form object do?

Run through this checklist before creating a service object:

1. **Does it belong on one model?** → Add a method to that model.
2. **Does it involve a form or multi-model input?** → Use a [form object](./form-objects.md).
3. **Is it complex query logic?** → Use a [query object](./query-objects.md).
4. **Is it shared behavior across models?** → Use a [concern](./concerns-and-mixins.md).
5. **Does it span multiple models with no natural home?** → **Now** consider a service object.

Legitimate triggers:
- Multi-model transaction that crosses aggregate boundaries (e.g. `PaymentReconciliation` touches `Invoice`, `Payment`, `Account`)
- External API call wired to model state changes
- Complex notification dispatch across channels
- Operations that must be testable in strict isolation from the database

## When NOT to

- Moving a model method out just because it's long — refactor the model instead
- Every new controller action — controllers can call model methods directly
- Wrapping a single `model.save` call — that's the anemic domain model in action

## Shape

Name service objects as **nouns** (not verb-suffixed `*Service`). The operation is the class name:

```ruby
# app/services/payment_reconciliation.rb
class PaymentReconciliation
  def initialize(invoice:, payment:)
    @invoice = invoice
    @payment = payment
  end

  def call
    ApplicationRecord.transaction do
      apply_payment
      close_invoice_if_paid
      send_receipt
    end
    Result.new(success: true, invoice: @invoice)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success: false, error: e.message)
  end

  private

  def apply_payment
    @invoice.payments.create!(
      amount_cents: @payment.amount_cents,
      paid_at: @payment.paid_at
    )
  end

  def close_invoice_if_paid
    @invoice.close! if @invoice.fully_paid?
  end

  def send_receipt
    InvoiceMailer.receipt(@invoice, @payment).deliver_later
  end

  Result = Data.define(:success, :invoice, :error) do
    def success? = success
  end
end
```

## Naming & location

- `app/services/<noun>.rb` or namespaced: `app/services/payments/reconciliation.rb`
- Class name is a **domain noun**, not a verb-service: `PaymentReconciliation`, `UserProvisioning`, `SubscriptionCancellation`
- Avoid: `ReconcilePaymentsService`, `UserService`, `CreateOrderService`
- Single-method entry point: always `call`, never `execute`, `run`, or `perform`

## Result objects

Return a structured result rather than booleans or raising:

```ruby
# Simple with Data.define (Ruby 3.2+):
Result = Data.define(:success, :record, :error) do
  def success? = success
  def failure? = !success
end

# Usage:
result = SomeOperation.new(...).call
if result.success?
  redirect_to result.record
else
  flash[:error] = result.error
  render :new
end
```

## Testing (Minitest)

Service objects are the most testable layer — test outcomes, not internals:

```ruby
# test/services/payment_reconciliation_test.rb
class PaymentReconciliationTest < ActiveSupport::TestCase
  setup do
    @invoice = invoices(:unpaid)
    @payment = payments(:new_payment)
  end

  test "returns success result when payment is valid" do
    result = PaymentReconciliation.new(invoice: @invoice, payment: @payment).call
    assert result.success?
  end

  test "closes invoice when fully paid" do
    PaymentReconciliation.new(invoice: @invoice, payment: @payment).call
    assert @invoice.reload.closed?
  end

  test "rolls back on error" do
    @payment.stubs(:paid_at).returns(nil)  # trigger a validation failure
    assert_no_difference "Payment.count" do
      PaymentReconciliation.new(invoice: @invoice, payment: @payment).call
    end
  end
end
```

## Common smells

- **`*Service` suffix** — rename to a domain noun: `UserRegistration`, not `RegistrationService`
- **Service that only wraps `model.save`** — that's anemic domain model; put it on the model
- **Service calling other services** — orchestration layers are hard to follow; if this is needed, consider a Saga/Process Manager pattern or rethink the domain model
- **Growing god service** — if it's over 80 lines, it's trying to do too much; split by responsibility
- **No result object** — returning `true/false` or raising forces callers to rescue; return a structured result

## See also

- [rails-antipatterns/anemic-domain-model](../../rails-antipatterns/rails-antipattern-anemic-domain-model/SKILL.md) — the antipattern service objects create when overused
- [form-objects.md](./form-objects.md) — handle form input before passing to a service
- [query-objects.md](./query-objects.md) — extract query logic instead of putting it in services
- [rails-models](../../rails/rails-models/SKILL.md) — where behavior belongs when a service object isn't warranted
- [rails-the-rails-way](../../rails/rails-the-rails-way/SKILL.md) — the default: fat models, thin controllers, no services unless necessary

## Examples

### External API integration

```ruby
# app/services/stripe_subscription_sync.rb
class StripeSubscriptionSync
  Result = Data.define(:success, :subscription, :error) do
    def success? = success
  end

  def initialize(user:)
    @user = user
  end

  def call
    stripe_sub = Stripe::Subscription.retrieve(@user.stripe_subscription_id)
    @user.subscription.update!(
      status: stripe_sub.status,
      current_period_end: Time.at(stripe_sub.current_period_end)
    )
    Result.new(success: true, subscription: @user.subscription, error: nil)
  rescue Stripe::StripeError => e
    Rails.error.report(e, context: { user_id: @user.id })
    Result.new(success: false, subscription: nil, error: e.message)
  end
end
```

### Multi-model order fulfillment

```ruby
# app/services/order_fulfillment.rb
class OrderFulfillment
  Result = Data.define(:success, :order, :shipment, :error) do
    def success? = success
  end

  def initialize(order:, fulfiller: current_user)
    @order = order
    @fulfiller = fulfiller
  end

  def call
    return failure("Order already fulfilled") if @order.fulfilled?
    return failure("Order not paid") unless @order.paid?

    ApplicationRecord.transaction do
      shipment = create_shipment
      @order.fulfill!(fulfilled_by: @fulfiller, shipment: shipment)
      notify_customer
      Result.new(success: true, order: @order, shipment: shipment, error: nil)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def create_shipment
    Shipment.create!(
      order: @order,
      tracking_number: ShippingProvider.book(@order),
      shipped_at: Time.current
    )
  end

  def notify_customer
    OrderMailer.shipment_notification(@order).deliver_later
  end

  def failure(message)
    Result.new(success: false, order: @order, shipment: nil, error: message)
  end
end
```

### Controller usage

```ruby
# app/controllers/admin/fulfillments_controller.rb
class Admin::FulfillmentsController < Admin::BaseController
  def create
    order = Order.find(params[:order_id])
    result = OrderFulfillment.new(order: order, fulfiller: current_user).call

    if result.success?
      redirect_to order, notice: "Order fulfilled. Shipment #{result.shipment.tracking_number}."
    else
      redirect_to order, alert: "Fulfillment failed: #{result.error}"
    end
  end
end
```

### Background job wrapping a service

```ruby
# app/jobs/subscription_sync_job.rb
class SubscriptionSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    result = StripeSubscriptionSync.new(user: user).call
    logger.warn "Sync failed for user #{user_id}: #{result.error}" unless result.success?
  end
end
```

### Minitest

```ruby
# test/services/order_fulfillment_test.rb
class OrderFulfillmentTest < ActiveSupport::TestCase
  setup do
    @order = orders(:paid_unfulfilled)
    @fulfiller = users(:admin)
  end

  test "returns success result" do
    ShippingProvider.stubs(:book).returns("TRACK123")
    result = OrderFulfillment.new(order: @order, fulfiller: @fulfiller).call
    assert result.success?
  end

  test "marks order as fulfilled" do
    ShippingProvider.stubs(:book).returns("TRACK123")
    OrderFulfillment.new(order: @order, fulfiller: @fulfiller).call
    assert @order.reload.fulfilled?
  end

  test "creates a shipment" do
    ShippingProvider.stubs(:book).returns("TRACK123")
    assert_difference "Shipment.count", 1 do
      OrderFulfillment.new(order: @order, fulfiller: @fulfiller).call
    end
  end

  test "returns failure for already-fulfilled order" do
    order = orders(:fulfilled)
    result = OrderFulfillment.new(order: order, fulfiller: @fulfiller).call
    refute result.success?
    assert_includes result.error, "already fulfilled"
  end

  test "rolls back on shipping error" do
    ShippingProvider.stubs(:book).raises(StandardError, "shipping unavailable")
    assert_no_difference ["Shipment.count"] do
      OrderFulfillment.new(order: @order, fulfiller: @fulfiller).call rescue nil
    end
  end
end
```
