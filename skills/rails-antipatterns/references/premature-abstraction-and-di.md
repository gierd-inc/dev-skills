# Antipattern: Premature Abstraction & Dependency Injection

## The smell
- Constructors that take a `repo:`, `clock:`, `mailer:`, `gateway:` keyword for every collaborator
- Repository / gateway / port classes wrapping a single Active Record model 1:1
- Test setup full of `instance_double(...)` / `class_double(...)` for things Rails already mocks (mailers, jobs, time)
- Only one production implementation exists; the "second" implementation is always a test double

## Why it hurts
- Costs are real: extra files, extra wiring, harder onboarding
- Benefits are imaginary — the second adapter never arrives
- Tests exercise the seam, not the behavior
- DHH/Manrubia: Rails *is* the abstraction layer. Don't build a second one to test it

## The fix
- **Use Active Record directly** — fixtures + test DB cover the "mocking" need
- Use Rails test helpers — `travel_to`, `assert_emails`, `perform_enqueued_jobs`, `freeze_time`
- **Real objects in tests** (see [mock-heavy-tests](mock-heavy-tests.md))
- Defer the abstraction until you genuinely have two implementations. YAGNI applies hardest in Rails

## When it's actually fine
You actually have (or will have within this PR) a second adapter — Stripe vs. Braintree, S3 vs. GCS, real vs. fake clock that can't be `travel_to`'d. Then a thin wrapper is justified.

## See also
- [service-object-soup](service-object-soup.md)
- [mock-heavy-tests](mock-heavy-tests.md)
- Rails testing reference: `../../rails/references/testing.md`

## Examples

### The smell

```ruby
class CreatePost
  def initialize(repo: PostRepository.new, clock: Time, mailer: PostMailer)
    @repo, @clock, @mailer = repo, clock, mailer
  end

  def call(attrs)
    post = @repo.build(attrs.merge(created_at: @clock.current))
    @repo.save(post)
    @mailer.notify(post).deliver_later
    post
  end
end

class PostRepository
  def build(attrs); Post.new(attrs); end
  def save(post);   post.save!; end
  def find(id);     Post.find(id); end
end
```

```ruby
# Test: exercises mocks, not behavior
test "creates a post" do
  repo   = instance_double(PostRepository)
  clock  = double(current: Time.zone.parse("2026-01-01"))
  mailer = class_double(PostMailer, notify: double(deliver_later: nil))

  expect(repo).to receive(:build).and_return(Post.new)
  expect(repo).to receive(:save)

  CreatePost.new(repo: repo, clock: clock, mailer: mailer).call(title: "x")
end
```

### The fix — vanilla Rails

```ruby
class Post < ApplicationRecord
  def self.create_and_notify!(attrs)
    create!(attrs).tap { |post| PostMailer.notify(post).deliver_later }
  end
end
```

```ruby
# Test: exercises behavior with real fixtures
test "create_and_notify! persists and emails" do
  travel_to Time.zone.parse("2026-01-01") do
    assert_emails 1 do
      post = Post.create_and_notify!(title: "x", author: users(:one))
      assert post.persisted?
      assert_equal Time.current, post.created_at
    end
  end
end
```
