---
name: oop-repository-pattern
description: Load rarely — only when you need to swap the data source behind a model (e.g. backing AR with an external API) or isolate the domain from persistence for strict test boundaries. ActiveRecord IS the repository; this pattern adds a layer on top only when AR can't be the adapter.
---

# Repository Pattern

> **You probably don't need this.** ActiveRecord already implements the Repository pattern. `Post.where(...)`, `Post.find(...)`, `post.save` — that's your repository. This skill documents when and how to add a repository layer *on top of* AR, and why the bar is high.

## What it is

The Repository pattern places a seam between your domain objects and the persistence mechanism. Code that needs data calls a repository; the repository decides how to fetch or store it. In a pure implementation, domain objects don't know about ActiveRecord at all.

## When AR is enough (almost always)

- You're using a relational database and have no plans to change
- You can test by hitting the real DB (Rails fixtures + Minitest — fast, honest)
- Scopes and query objects cover your query complexity

## When the repository pattern earns its cost

- **Non-AR data sources**: fetching data from an external API, a JSON file, or another DB, where you want the rest of the app to treat it like a collection of domain objects
- **Hexagonal architecture / boundary isolation**: strict ports-and-adapters where domain logic must be testable without a database at all
- **Swappable backends**: e.g. a read model backed by Elasticsearch, with the same interface as the AR-backed model
- **Legacy migration seam**: wrapping a legacy data layer while incrementally replacing it

## Shape

```ruby
# app/repositories/user_repository.rb
class UserRepository
  def find(id)
    User.find(id)
  end

  def find_by_email(email)
    User.find_by(email: email)
  end

  def save(user)
    user.save
  end

  def active
    User.active
  end
end
```

This is minimal overhead when AR is the backend. The real value emerges when you substitute the backend:

```ruby
# For tests, swap the AR repo with an in-memory one:
class InMemoryUserRepository
  def initialize
    @store = {}
    @next_id = 1
  end

  def find(id)
    @store[id] || raise(ActiveRecord::RecordNotFound)
  end

  def find_by_email(email)
    @store.values.find { |u| u.email == email }
  end

  def save(user)
    user.id ||= @next_id
    @next_id += 1
    @store[user.id] = user
    true
  end

  def active
    @store.values.select(&:active?)
  end
end
```

## Naming & location

- `app/repositories/<model>_repository.rb` → `UserRepository`
- Namespaced when scoped: `app/repositories/billing/invoice_repository.rb`
- Method names match retrieval intent: `find`, `find_by_email`, `all`, `active`, `save`, `delete`
- Never `get_*` or `fetch_*` — use plain nouns or AR-style names

## Dependency injection

The pattern only delivers isolation if you inject the repository:

```ruby
class UserAuthenticationService
  def initialize(users: UserRepository.new)
    @users = users
  end

  def authenticate(email:, password:)
    user = @users.find_by_email(email)
    user if user&.authenticate(password)
  end
end

# In tests, inject the in-memory repo:
service = UserAuthenticationService.new(users: InMemoryUserRepository.new)
```

## Testing (Minitest)

Testing with an in-memory repository is the main reason to introduce this pattern:

```ruby
# test/services/user_authentication_service_test.rb
class UserAuthenticationServiceTest < ActiveSupport::TestCase
  setup do
    @repo = InMemoryUserRepository.new
    @user = OpenStruct.new(
      email: "ryan@example.com",
      authenticate: ->(pw) { pw == "secret" ? true : nil }
    )
    @repo.save(@user)
    @service = UserAuthenticationService.new(users: @repo)
  end

  test "returns user with correct credentials" do
    result = @service.authenticate(email: "ryan@example.com", password: "secret")
    assert_equal @user, result
  end

  test "returns nil with wrong password" do
    result = @service.authenticate(email: "ryan@example.com", password: "wrong")
    assert_nil result
  end
end
```

## Common smells

- **Thin pass-through repo** — if every method just calls the same AR method (`.find` → `User.find`), you have zero benefit and double the maintenance; delete it
- **Repo with business logic** — `UserRepository#registered_this_week_and_has_subscription` is a query object or a scope, not a repo method
- **Mandatory repo without substitution** — if you never substitute the backend, you're paying the abstraction cost for nothing
- **Domain objects extending ApplicationRecord** — if your domain objects depend on AR, the repo seam is fake

## See also

- [oop-query-objects](../oop-query-objects/SKILL.md) — the simpler, more idiomatic way to encapsulate complex queries without a full repo layer
- [oop-service-objects](../oop-service-objects/SKILL.md) — often the caller that depends on an injected repository
- [rails-models](../../rails/rails-models/SKILL.md) — scopes, query methods: AR as repository (the default)
- [rails-testing](../../rails/rails-testing/SKILL.md) — Minitest with fixtures: the Rails way to test without mocking the database

See `references/examples.md` for annotated code samples.
