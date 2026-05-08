# Null Objects

## What it is

A Null Object implements the same interface as the real object but returns safe, do-nothing defaults. It eliminates nil checks at call sites by making `nil` itself unreachable — callers just call methods without guards.

Classic examples: `GuestUser` (unauthenticated visitor), `NullAvatar`, `NullOrganization`, `NullSubscription`.

## Would a fat model do?

Yes — if the nil check lives in one or two places, add a model method or a view helper. Extract a Null Object when:

- The same nil guard (with the same fallback) appears in 3+ places across views, controllers, or other models
- The "nil case" has real behavior (e.g. a GuestUser can browse but not post, redirects on checkout, etc.)
- You want `current_user.name` to work unconditionally in every view

## When NOT to

- A single nil check in one view — use `||` or `presence` inline
- Simple conditional that differs at every call site — a null object forces uniform behavior; if fallbacks differ everywhere, it's wrong
- When you actually need to know "is this real or null?" — that information gets hidden by the pattern

## Shape

```ruby
# app/models/guest_user.rb
class GuestUser
  def id = nil
  def name = "Guest"
  def email = nil
  def admin? = false
  def authenticated? = false
  def to_param = nil

  # Add every method your views/controllers call on User
end

# In ApplicationController:
def current_user
  @current_user ||= User.find_by(id: session[:user_id]) || GuestUser.new
end
```

Every call site becomes:
```ruby
current_user.name       # "Ryan" or "Guest" — no &. needed
current_user.admin?     # false for guests
current_user.authenticated?  # gate in one place
```

## Naming & location

- Files live alongside what they stand in for: `app/models/guest_user.rb`, or in `app/models/null/` for a namespace
- Name with the context, not the pattern: `GuestUser` not `NullUser`; `MissingAvatar` not `NullAvatar`
- Use `Null` prefix only as a last resort when there's no better domain name

## Implementing with SimpleDelegator

When the null object shares most behavior with the real object, use `SimpleDelegator` to delegate by default and override only the exceptions:

```ruby
# If you have a real Subscription model and need a null version:
class NullSubscription < SimpleDelegator
  def initialize
    super(Subscription.new)  # or a frozen default object
  end

  def active? = false
  def plan_name = "Free"
  def expires_at = nil
end
```

## Testing (Minitest)

```ruby
class GuestUserTest < ActiveSupport::TestCase
  setup { @guest = GuestUser.new }

  test "name returns Guest" do
    assert_equal "Guest", @guest.name
  end

  test "authenticated? returns false" do
    refute @guest.authenticated?
  end

  test "responds to same interface as User" do
    User.instance_methods(false).each do |method|
      assert @guest.respond_to?(method), "GuestUser missing ##{method}"
    end
  end
end
```

## Common smells

- **Null object that returns nil** — defeats the purpose; every method should return a safe value, never nil
- **Null object with branching logic** — if it needs `if real?`, you've recreated the problem inside the null object
- **Hidden nils** — if callers still need to distinguish real from null (e.g., for saving), expose `authenticated?` or `persisted?` explicitly rather than breaking the interface
- **Interface drift** — as `User` gains new methods, `GuestUser` falls behind; the interface test above catches this

## See also

- [value-objects.md](./value-objects.md) — closely related: null objects are often value objects with a safe-default interface
- [rails-models](../../rails/rails-models/SKILL.md) — where behavior belongs when a null object isn't warranted
- [rails-the-rails-way](../../rails/rails-the-rails-way/SKILL.md) — prefer model methods before introducing new classes

## Examples

### GuestUser (full example)

```ruby
# app/models/guest_user.rb
class GuestUser
  # Identity
  def id = nil
  def to_param = nil
  def persisted? = false

  # Display
  def name = "Guest"
  def email = nil
  def initials = "?"
  def avatar_url = ActionController::Base.helpers.asset_path("default_avatar.png")

  # Auth / capability
  def authenticated? = false
  def admin? = false
  def can_post? = false

  # Subscription (if User has one)
  def subscription = NullSubscription.new

  # Prevents accidentally calling save/update on a guest
  def save = false
  def update(**) = false
end
```

### ApplicationController integration

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) || GuestUser.new
  end

  def user_signed_in?
    current_user.authenticated?
  end

  def require_authentication
    redirect_to sign_in_path unless user_signed_in?
  end
end
```

### NullSubscription

```ruby
# app/models/null_subscription.rb
class NullSubscription
  def active? = false
  def trial? = false
  def plan_name = "Free"
  def expires_at = nil
  def can_access?(feature) = false

  # Turbo-safe: respond to persisted? so `form_with(model:)` doesn't blow up
  def persisted? = false
  def to_param = nil
end
```

### View usage (no nil guards needed)

```erb
<%# Before: ugly nil guards everywhere %>
<%= current_user&.name || "Guest" %>
<% if current_user && current_user.admin? %>
  <%= link_to "Admin", admin_path %>
<% end %>

<%# After: clean, uniform interface %>
<%= current_user.name %>
<% if current_user.admin? %>
  <%= link_to "Admin", admin_path %>
<% end %>
```

### Interface coverage test

```ruby
# test/models/guest_user_test.rb
class GuestUserTest < ActiveSupport::TestCase
  setup { @guest = GuestUser.new }

  # Verify the null object doesn't fall behind as User grows:
  EXPECTED_METHODS = %i[
    id name email admin? authenticated? avatar_url
    can_post? subscription persisted? to_param
  ]

  EXPECTED_METHODS.each do |method|
    test "responds to ##{method}" do
      assert @guest.respond_to?(method)
    end
  end

  test "name returns a safe default" do
    assert_equal "Guest", @guest.name
  end

  test "authenticated? is false" do
    refute @guest.authenticated?
  end
end
```
