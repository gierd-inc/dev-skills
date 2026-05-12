# Antipattern: Service Object Soup

## The smell
- `app/services/` full of verb-named `*Service` classes (`CreateUserService`, `UpdateUserService`, `SendWelcomeEmailService`)
- Each has `def self.call(...)` or `def initialize; def call`
- Models are inert — services orchestrate every change
- Tests stub the service collaborators rather than exercising the model
- Discoverability: "where does X happen?" → "search `services/`"

## Why it hurts
- Models become anemic ([anemic-domain-model](anemic-domain-model.md))
- Verb-named classes don't compose — DI gymnastics needed to chain them
- Encourages procedural code in OO clothing
- DHH/Manrubia: "Vanilla Rails is plenty." Concerns + POROs + AR verbs cover most cases

## The fix (preferred order)
1. **Method on the model** — `user.charge_card(token)`, `post.publish`
2. **Concern** for grouped behavior — `User::Billable`, `Post::Publishable`
3. **PORO named as a noun** (not `*Service`) — `Reconciliation`, `OnboardingFlow`, `WeeklyDigest`
4. **Active Record model** when the operation is itself an entity — `Subscription`, `OrderPayment`
5. **Job** for async side effects

## When it's actually fine
Operations spanning clearly-separated subsystems (payments, search indexing, third-party integrations) and not belonging to any one model can live in their own folder. Even then, name them as **nouns**, avoid `*Service`, and avoid class-method `.call` as the only API.

## See also
- [anemic-domain-model](anemic-domain-model.md)
- Rails "the Rails way" reference: `../../rails/references/the-rails-way.md`
- [premature-abstraction-and-di](premature-abstraction-and-di.md)

## Examples

### The smell

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

### The fix — method on the model

```ruby
class User < ApplicationRecord
  def self.create_with_welcome!(attrs)
    create!(attrs).tap { |user| UserMailer.welcome(user).deliver_later }
  end
end

# Call site:
user = User.create_with_welcome!(params)
```

### The fix — concern when behavior clusters

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

### When extraction is justified — name as a noun

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
