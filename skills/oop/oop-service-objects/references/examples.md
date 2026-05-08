# Service Object Examples

## External API integration

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

## Multi-model order fulfillment

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

## Controller usage

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

## Background job wrapping a service

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

## Minitest

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
