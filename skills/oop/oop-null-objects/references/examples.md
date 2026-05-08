# Null Object Examples

## GuestUser (full example)

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

## ApplicationController integration

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

## NullSubscription

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

## View usage (no nil guards needed)

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

## Interface coverage test

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
