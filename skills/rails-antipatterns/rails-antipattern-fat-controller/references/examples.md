# Fat Controller — Code Samples

## The smell

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    if current_user.credit_balance >= @order.total
      current_user.credit_balance -= @order.total
      current_user.save!
      @order.status = "paid"
    else
      charge = Stripe::Charge.create(amount: @order.total, source: params[:token])
      @order.stripe_id = charge.id
      @order.status = charge.paid? ? "paid" : "failed"
    end
    @order.save!
    OrderMailer.confirmation(@order).deliver_later if @order.paid?
    redirect_to @order
  end
end
```

## The fix — push to the model

```ruby
class OrdersController < ApplicationController
  def create
    @order = current_user.orders.create_and_pay!(order_params, token: params[:token])
    redirect_to @order
  rescue Order::PaymentFailed => e
    redirect_to new_order_path, alert: e.message
  end
end

class Order < ApplicationRecord
  class PaymentFailed < StandardError; end

  def self.create_and_pay!(attrs, token:)
    create!(attrs).tap { |order| order.pay!(token: token) }
  end

  def pay!(token:)
    transaction do
      Billing.charge(self, token: token)
      update!(status: :paid)
      OrderMailer.confirmation(self).deliver_later
    end
  rescue Billing::Error => e
    raise PaymentFailed, e.message
  end
end
```

## Even better — promote to a resource

```ruby
# routes.rb
resources :orders do
  resource :payment, only: [:create]
end

class PaymentsController < ApplicationController
  def create
    @order = current_user.orders.find(params[:order_id])
    @payment = @order.payments.create!(token: params[:token])
    redirect_to @order
  end
end
```
