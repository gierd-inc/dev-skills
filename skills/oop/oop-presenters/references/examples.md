# Presenter Examples

## UserPresenter (SimpleDelegator)

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < SimpleDelegator
  def display_name
    name.presence || email
  end

  def avatar_or_initials
    if avatar.attached?
      # return avatar URL
    else
      initials
    end
  end

  def initials
    name.split.map { |n| n[0].upcase }.first(2).join
  end

  def role_badge
    admin? ? "Admin" : "Member"
  end

  def role_badge_class
    admin? ? "badge-purple" : "badge-gray"
  end

  def last_seen
    last_sign_in_at ? "#{time_ago_in_words(last_sign_in_at)} ago" : "Never"
  end
end
```

## Context-specific presenter

```ruby
# app/presenters/invoices/line_item_presenter.rb
module Invoices
  class LineItemPresenter < SimpleDelegator
    def formatted_unit_price
      "$#{'%.2f' % (unit_price_cents / 100.0)}"
    end

    def formatted_total
      "$#{'%.2f' % (total_cents / 100.0)}"
    end

    def quantity_label
      quantity == 1 ? "1 unit" : "#{quantity} units"
    end
  end
end
```

## Controller usage

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def show
    @user = UserPresenter.new(User.find(params[:id]))
  end

  def index
    @users = User.active.map { |u| UserPresenter.new(u) }
  end
end
```

## View usage (ERB)

```erb
<%# app/views/users/show.html.erb %>
<div class="user-card">
  <span class="badge <%= @user.role_badge_class %>">
    <%= @user.role_badge %>
  </span>

  <h1><%= @user.display_name %></h1>
  <p>Last seen: <%= @user.last_seen %></p>
</div>
```

## Plain Ruby presenter (explicit delegation)

```ruby
# app/presenters/post_summary_presenter.rb
# Use when you want tight control over the interface (not SimpleDelegator):
class PostSummaryPresenter
  def initialize(post)
    @post = post
  end

  delegate :id, :title, :slug, :published_at, :author, to: :@post

  def excerpt
    @post.body.to_plain_text.truncate(160)
  end

  def reading_time
    words = @post.body.to_plain_text.split.size
    "#{(words / 200.0).ceil} min read"
  end

  def published_label
    published_at ? published_at.strftime("%B %-d, %Y") : "Draft"
  end
end
```

## Minitest

```ruby
# test/presenters/user_presenter_test.rb
class UserPresenterTest < ActiveSupport::TestCase
  setup do
    @user = users(:ryan)
    @presenter = UserPresenter.new(@user)
  end

  test "display_name falls back to email" do
    @user.stubs(:name).returns(nil)
    user = UserPresenter.new(@user)
    assert_equal @user.email, user.display_name
  end

  test "initials from name" do
    assert_equal "RH", @presenter.initials
  end

  test "delegates id to model" do
    assert_equal @user.id, @presenter.id
  end

  test "to_param delegates so URL helpers work" do
    assert_equal @user.to_param, @presenter.to_param
  end
end
```
