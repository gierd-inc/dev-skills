---
name: oop-policy-objects
description: Use when authorization logic is scattered across controllers and models, when `if current_user.admin?` checks are duplicated, or when you need per-resource per-action access rules. Load when building policies, working with Pundit, or centralizing who can do what.
---

# Policy Objects

## What it is

A Policy Object answers the question "can this user perform this action on this resource?" It encapsulates authorization logic for one resource, with one method per action. Controllers and views query the policy rather than embedding inline `admin?` or ownership checks.

Policy objects work well with [Pundit](https://github.com/varvet/pundit) (the gem), but the pattern is plain Ruby and doesn't require it.

## Would inline checks do?

Keep authorization inline when:
- There is only one role check (`admin?` or `owner?`) at one call site
- The app is simple enough that `current_user.admin?` everywhere is clear

Extract a policy object when:
- The same resource has different rules for different actions (`can view? != can edit?`)
- Multiple roles with different permissions (admin, editor, viewer)
- Authorization logic is duplicated across 2+ controllers or views
- You want to test authorization in isolation

## When NOT to

- Pure authentication gates (`require_authentication` before action) — that's not authorization
- Feature flags — those belong in a flag system, not a policy
- Simple ownership checks that appear only once — inline is fine

## Shape (plain Ruby, no Pundit)

```ruby
# app/policies/post_policy.rb
class PostPolicy
  def initialize(user, post)
    @user = user
    @post = post
  end

  def show?
    @post.published? || author? || @user.admin?
  end

  def edit?
    author? || @user.admin?
  end

  def destroy?
    @user.admin?
  end

  private

  def author?
    @post.author_id == @user.id
  end
end
```

## Shape (Pundit convention)

With Pundit, the same class also gets a `Scope` inner class:

```ruby
# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def show?
    record.published? || author? || user.admin?
  end

  def edit?
    author? || user.admin?
  end

  def destroy?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(published_at: ..Time.current)
             .or(scope.where(author: user))
      end
    end
  end

  private

  def author?
    record.author_id == user.id
  end
end
```

## Naming & location

- `app/policies/post_policy.rb` → `PostPolicy`
- `app/policies/admin/report_policy.rb` → `Admin::ReportPolicy`
- Convention (both plain and Pundit): `ModelPolicy`, one file per resource
- Methods match controller actions: `index?`, `show?`, `create?`, `edit?`, `update?`, `destroy?`
- Add custom actions: `publish?`, `archive?`, `export?`

## Using without Pundit (manual)

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def edit
    @post = Post.find(params[:id])
    policy = PostPolicy.new(current_user, @post)
    raise Pundit::NotAuthorizedError unless policy.edit?
  end
end
```

Or wrap in a helper:

```ruby
# app/controllers/application_controller.rb
def authorize!(record, action)
  policy_class = "#{record.class}Policy".constantize
  policy = policy_class.new(current_user, record)
  raise NotAuthorizedError unless policy.public_send("#{action}?")
end
```

## In views

```erb
<% policy = PostPolicy.new(current_user, @post) %>
<% if policy.edit? %>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>

<%# With Pundit helper: %>
<% if policy(@post).destroy? %>
  <%= button_to "Delete", @post, method: :delete %>
<% end %>
```

## Testing (Minitest)

```ruby
# test/policies/post_policy_test.rb
class PostPolicyTest < ActiveSupport::TestCase
  setup do
    @admin   = users(:admin)
    @author  = users(:ryan)
    @visitor = users(:guest_user)
    @published_post   = posts(:published)
    @draft_post       = posts(:draft)
  end

  test "admin can destroy any post" do
    assert PostPolicy.new(@admin, @published_post).destroy?
  end

  test "non-admin cannot destroy" do
    refute PostPolicy.new(@author, @published_post).destroy?
  end

  test "author can edit own post" do
    assert PostPolicy.new(@author, @draft_post).edit?
  end

  test "visitor cannot edit" do
    refute PostPolicy.new(@visitor, @draft_post).edit?
  end

  test "everyone can show a published post" do
    assert PostPolicy.new(@visitor, @published_post).show?
  end

  test "only author/admin can show draft" do
    assert  PostPolicy.new(@author, @draft_post).show?
    refute  PostPolicy.new(@visitor, @draft_post).show?
  end
end
```

## Common smells

- **Policy that queries the database** — policies should use already-loaded associations; if you need to query, preload in the controller
- **Policy with business logic** — "can publish?" depends on subscription status? Extract that check to the model (`post.publishable_by?(user)`) and call it from the policy
- **Missing actions** — only testing `admin?`; verify fine-grained `edit?` vs `destroy?` rules
- **Policy in the model** — models shouldn't reference `current_user` or User by role; that's the policy's job

## See also

- [oop-service-objects](../oop-service-objects/SKILL.md) — for operations that the policy says are allowed
- [rails-security](../../rails/rails-security/SKILL.md) — authentication, secure defaults, session management
- [rails-controllers](../../rails/rails-controllers/SKILL.md) — `before_action` and how controllers call policies

See `references/examples.md` for annotated code samples.
