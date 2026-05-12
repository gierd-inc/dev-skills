# Antipattern: Fat Model / God Object

## The smell
- One model owning many unrelated responsibilities (auth + billing + search + notifications + exports)
- Hundreds-to-thousands of lines, constants and scopes sprawling
- Every PR touches it; merge conflicts cluster on it

## Why it hurts
- Cognitive load — readers can't tell what the model *is*
- Tests slow because every test loads every concern's deps
- Encourages "just add it to User" forever

## The fix (in order of preference)
1. **Concerns** in `app/models/concerns/` for behavior that genuinely belongs to the model but is logically grouped (`User::Authenticatable`, `User::Billable`)
2. **Value objects / POROs** for cohesive logic operating on data (`PasswordStrength`, `SubscriptionStatus`)
3. **A new Active Record model** when the "concern" is actually a missing entity (`AccountClosure`)
4. **Background jobs** for side effects

Avoid `app/services/UserService` as the dumping ground — see [service-object-soup](service-object-soup.md).

## When it's actually fine
A long model that's genuinely one cohesive concept (e.g. `Invoice` with line-item math, totals, state) is fine. Length alone isn't the smell — *unrelated* responsibilities are.

## See also
- Rails models reference: `../../rails/references/models.md`
- [anemic-domain-model](anemic-domain-model.md)
- [service-object-soup](service-object-soup.md)

## Examples

### The smell

```ruby
class User < ApplicationRecord
  # 800 lines: auth, billing, search, notifications, exports, ...
  has_secure_password
  has_many :invoices
  has_many :subscriptions

  def charge_card(token); end
  def send_slack_notification; end
  def reindex_in_search; end
  def export_to_csv; end
  def reset_password!; end
  def audit_changes; end
  # ... 80 more methods
end
```

### The fix — concerns

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Authenticatable, Billable, Searchable
end

# app/models/user/billable.rb
module User::Billable
  extend ActiveSupport::Concern

  included do
    has_many :invoices
    has_many :subscriptions
  end

  def charge_card(token)
    # ...
  end
end
```

### The fix — value object / PORO

```ruby
class PasswordStrength
  def initialize(password) = @password = password
  def score; end
  def acceptable? = score >= 3
end

class User < ApplicationRecord
  def password_strength = PasswordStrength.new(password)
end
```

### The fix — promote to a real entity

```ruby
# Instead of User#close_account doing a 50-line workflow:
class AccountClosure < ApplicationRecord
  belongs_to :user
  after_create_commit :perform!

  private

  def perform!
    user.subscriptions.active.find_each(&:cancel!)
    user.update!(closed_at: Time.current)
    AccountClosureMailer.confirmation(self).deliver_later
  end
end
```
