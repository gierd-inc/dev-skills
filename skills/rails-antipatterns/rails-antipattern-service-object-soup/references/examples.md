# Service Object Soup — Code Samples

## The smell

```
app/services/
  create_user_service.rb
  update_user_service.rb
  delete_user_service.rb
  send_welcome_email_service.rb
  charge_card_service.rb
  publish_post_service.rb
  notify_subscribers_service.rb
  ...
```

```ruby
class CreateUserService
  def self.call(params)
    new(params).call
  end

  def initialize(params); @params = params; end

  def call
    user = User.new(@params)
    user.save!
    SendWelcomeEmailService.call(user)
    user
  end
end

# Call site:
user = CreateUserService.call(params)
```

## The fix — method on the model

```ruby
class User < ApplicationRecord
  def self.create_with_welcome!(attrs)
    create!(attrs).tap { |user| UserMailer.welcome(user).deliver_later }
  end
end

# Call site:
user = User.create_with_welcome!(params)
```

## The fix — concern when behavior clusters

```ruby
class User < ApplicationRecord
  include Billable
end

# app/models/user/billable.rb
module User::Billable
  extend ActiveSupport::Concern

  def charge_card(token)
    Stripe::Charge.create(amount: outstanding_balance, source: token, customer: stripe_id)
  end

  def refund_last_payment
    # ...
  end
end
```

## When extraction is justified — name as a noun

```ruby
# Spans Invoice, Payment, Account — no single owner. NOT *Service.
class MonthlyReport
  def initialize(account, month: Date.current.beginning_of_month)
    @account, @month = account, month
  end

  def generate
    # ...
  end
end

MonthlyReport.new(account).generate
```
