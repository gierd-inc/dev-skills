# Antipattern: God Helper Module

## The smell
- `ApplicationHelper` with dozens of unrelated methods
- Helpers that perform queries (`fetch_recent_posts`, `current_admin_count`)
- Business calculations in helpers (`calculate_tax(order)`)
- Predicates about the current user as global helpers
- Method names colliding or shadowing model methods

## Why it hurts
- Pollutes the global view namespace
- Mixes formatting (legitimate helper work) with queries and domain logic
- Hard to tell which view uses which helper — refactoring is risky
- New devs add to it because there's no obvious better home

## The fix
- **Split by topic**: `MoneyHelper`, `AvatarHelper`, `NavigationHelper` (auto-included by Rails)
- **Move queries to models or controllers**, not helpers
- **Move business calculations to models or POROs** (`order.tax`, not `calculate_tax(order)`)
- Keep helpers focused on **presentation**: HTML structure, formatting, escaping, i18n wrappers

## When it's actually fine
A small, cohesive `ApplicationHelper` with truly cross-cutting formatters (one or two methods) is fine. The smell is *unrelated* responsibilities and *non-presentation* logic.

## See also
- Rails helpers reference: `../../rails/references/helpers.md`
- Rails views reference: `../../rails/references/views.md`
- [php-itis-views](php-itis-views.md)

## Examples

### The smell

```ruby
module ApplicationHelper
  def humanized_money(cents); end
  def gravatar_for(user); end
  def admin?; current_user&.admin?; end
  def fetch_recent_posts; Post.recent.limit(5); end          # querying
  def calculate_tax(order); order.subtotal * 0.0875; end      # business logic
  def truncate_html(text, length); end
  def render_breadcrumbs; end
  def time_ago_in_local_zone(t); end
  # ... 80 more methods
end
```

### The fix — split, move queries to controllers, move math to models

```ruby
# app/helpers/money_helper.rb
module MoneyHelper
  def humanized_money(cents)
    number_to_currency(cents.to_d / 100)
  end
end

# app/helpers/avatar_helper.rb
module AvatarHelper
  def gravatar_for(user, size: 48)
    image_tag gravatar_url(user, size: size), class: "avatar"
  end
end

# app/helpers/navigation_helper.rb
module NavigationHelper
  def render_breadcrumbs
    # ...
  end
end
```

```ruby
# Move query to controller
class PostsController < ApplicationController
  def index
    @posts        = Post.recent
    @recent_posts = Post.recent.limit(5)
  end
end

# Move business logic to model
class Order < ApplicationRecord
  TAX_RATE = 0.0875
  def tax = subtotal * TAX_RATE
end
```

```erb
<%= humanized_money(@order.tax) %>
```
