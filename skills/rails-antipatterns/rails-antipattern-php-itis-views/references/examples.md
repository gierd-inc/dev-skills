# PHP-itis — Code Samples

## The smell

```erb
<% if @user.subscription && @user.subscription.active? &&
      @user.subscription.plan_id == 3 &&
      Date.today > @user.subscription.trial_ends_at %>
  <% total = 0 %>
  <% @user.invoices.each do |i| %>
    <% total += i.amount if i.paid? && i.created_at.year == Date.today.year %>
  <% end %>
  <p>You owe: $<%= sprintf("%.2f", total / 100.0) %></p>
<% end %>
```

## The fix — predicates and methods on the model

```ruby
class User < ApplicationRecord
  has_one :subscription
  has_many :invoices

  def owes_for_premium_trial?
    subscription&.active? &&
      subscription.premium? &&
      subscription.trial_ended?
  end

  def amount_owed_this_year
    invoices.paid.this_year.sum(:amount)
  end
end

class Subscription < ApplicationRecord
  PREMIUM_PLAN_ID = 3
  def premium?      = plan_id == PREMIUM_PLAN_ID
  def trial_ended?  = trial_ends_at && trial_ends_at < Date.current
end

class Invoice < ApplicationRecord
  scope :paid,      -> { where.not(paid_at: nil) }
  scope :this_year, -> { where(created_at: Time.current.all_year) }
end
```

```ruby
# app/helpers/money_helper.rb
module MoneyHelper
  def humanized_money(cents)
    number_to_currency(cents.to_d / 100)
  end
end
```

```erb
<% if @user.owes_for_premium_trial? %>
  <p>You owe: <%= humanized_money(@user.amount_owed_this_year) %></p>
<% end %>
```
