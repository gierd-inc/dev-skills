# Fat Model / God Object — Code Samples

## The smell

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

## The fix — concerns

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

## The fix — value object / PORO

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

## The fix — promote to a real entity

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
