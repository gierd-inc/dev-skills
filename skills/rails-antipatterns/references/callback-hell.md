# Antipattern: Callback Hell

## The smell
- Multiple `after_create` / `after_save` / `after_commit` callbacks doing side effects (charges, emails, jobs, external APIs)
- `update_columns` used as a workaround to skip them
- Tests must stub or skip callbacks to keep the suite fast
- "Save without notifying" requires hacks

## Why it hurts
- Implicit side effects — call sites can't see what happens
- Callback ordering bugs are silent and rare-to-reproduce
- Re-saving for unrelated reasons re-fires effects
- Hard to compose alternative flows (admin imports, backfills)

## The fix
- **Make side effects explicit at the call site.** Replace lifecycle callbacks with named methods controllers/jobs invoke
- Push async work to **jobs** triggered explicitly, not from `after_commit`
- Reserve callbacks for **invariants tightly coupled to persistence**: `before_validation` normalization, derived columns, `dependent: :destroy` — things that don't reach outside the row

## When it's actually fine
- `before_validation` for normalization (email downcase, slug generation)
- `after_commit` for *idempotent* bookkeeping that genuinely must follow every persistence
- `dependent: :destroy`

## See also
- Rails models reference: `../../rails/references/models.md`
- Rails jobs reference: `../../rails/references/jobs.md`
- [fat-model-god-object](fat-model-god-object.md)

## Examples

### The smell

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

### The fix — explicit verb on the model

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

### What's still fine in callbacks

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
