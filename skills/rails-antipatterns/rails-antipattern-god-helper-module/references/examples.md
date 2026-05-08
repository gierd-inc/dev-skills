# God Helper Module — Code Samples

## The smell

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

## The fix — split, move queries to controllers, move math to models

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
