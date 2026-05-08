# Voyeuristic Model — Code Samples

## The smell

```erb
<%= @order.customer.address.city %>
<%= @invoice.account.owner.profile.display_name %>
<%= @user&.organization&.billing_address&.country %>
```

```ruby
# Repeated across controllers
if @order.customer.address.country == "US"
  # ...
end
```

## The fix — delegate

```ruby
class Order < ApplicationRecord
  belongs_to :customer
  delegate :city, :country, to: :customer
  delegate :display_name, to: :customer, prefix: true
end

# Call site:
@order.city
@order.customer_display_name
```

## The fix — intent-revealing method

```ruby
class Invoice < ApplicationRecord
  def billed_to
    account.owner.profile.display_name
  end

  def billable_in_us?
    account.address.country == "US"
  end
end

# Call site:
<%= @invoice.billed_to %>
```
