# Antipattern: Voyeuristic Model

## The smell
- Callers traversing 3+ associations to read data: `order.customer.address.city`
- Same chain repeated across views, controllers, mailers
- `&.` peppered through chains to dodge nil

## Why it hurts
- A nil anywhere raises `NoMethodError on nil`
- Renaming or restructuring an association breaks every call site
- Views and controllers grow knowledge of model internals
- Hard to mock or stub for tests

## The fix
- Use `delegate` for thin pass-throughs (`delegate :city, to: :customer`)
- Add a method that expresses the **intent**, not the path (`invoice.billed_to`)
- Tell, don't ask: push the question down to the object that owns the data
- Ensure non-optional `belongs_to` (Rails default) so `&.` isn't needed

## When it's actually fine
A two-step reach (`post.author.name`) inside a model method is usually fine. The smell is depth-3+ chains in views/controllers, or repeating the same chain in many places.

## See also
- Rails models reference: `../../rails/references/models.md`
- [php-itis-views](php-itis-views.md)

## Examples

### The smell

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

### The fix — delegate

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

### The fix — intent-revealing method

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
