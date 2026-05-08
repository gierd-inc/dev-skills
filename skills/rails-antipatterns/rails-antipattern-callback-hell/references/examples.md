# Callback Hell — Code Samples

## The smell

```ruby
class Order < ApplicationRecord
  after_create  :charge_card
  after_create  :send_receipt_email
  after_create  :notify_warehouse
  after_update  :reindex_search
  after_save    :recalculate_totals
  after_save    :audit_changes
  before_destroy :cancel_subscription_if_last
end

# Now this trivial update charges a card in tests:
Order.find(1).update!(notes: "added shipping note")
```

## The fix — explicit verb on the model

```ruby
class Order < ApplicationRecord
  def place!
    transaction do
      save!
      Billing.charge(self)
      OrderMailer.receipt(self).deliver_later
      WarehouseNotificationJob.perform_later(self)
    end
  end
end

# Call site reads what actually happens:
order = Order.new(order_params)
order.place!
```

## What's still fine in callbacks

```ruby
class User < ApplicationRecord
  before_validation :normalize_email
  before_save :set_default_role, on: :create

  has_many :posts, dependent: :destroy

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def set_default_role
    self.role ||= "member"
  end
end
```
