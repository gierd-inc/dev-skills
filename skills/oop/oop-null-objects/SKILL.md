---
name: oop-null-objects
description: Use when code is littered with `current_user&.name`, `avatar.present? ? avatar.url : default_url`, or `if subscription` guards that repeat the same fallback in multiple places. Replace nil with a stand-in object that honors the full interface.
---

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

- [oop-value-objects](../oop-value-objects/SKILL.md) — closely related: null objects are often value objects with a safe-default interface
- [rails-models](../../rails/rails-models/SKILL.md) — where behavior belongs when a null object isn't warranted
- [rails-the-rails-way](../../rails/rails-the-rails-way/SKILL.md) — prefer model methods before introducing new classes

See `references/examples.md` for annotated code samples.
