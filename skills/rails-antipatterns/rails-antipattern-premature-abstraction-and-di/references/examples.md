# Premature Abstraction & DI — Code Samples

## The smell

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

## The fix — vanilla Rails

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
