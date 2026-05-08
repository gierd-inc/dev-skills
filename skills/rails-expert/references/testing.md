# Rails Testing

This codebase uses Minitest with fixtures exclusively. Do NOT use RSpec or FactoryBot.

## Core Principles

- Each test file must match the class/module under test
- Prefer built-in assertions: `assert_difference`, `assert_changes`, `assert_predicate`, `assert_includes`, `assert_no_difference`
- Use descriptive test names: `test "admin can view dashboard"`
- Avoid mocks/stubs — prefer real Rails behavior end-to-end
- Keep tests fast and deterministic

## Model Tests

- Place in `test/models/`, use `ActiveSupport::TestCase`
- Test validations, associations, scopes, callbacks, and business logic
- Reference fixtures by label: `users(:john)`

## Controller Tests

- Place in `test/controllers/`, use `ActionDispatch::IntegrationTest`
- Test RESTful actions, authentication, and Turbo Stream responses
- Assert redirects, flash messages, response status, and DOM structure

## Job Tests

- Place in `test/jobs/`, use `ActiveJob::TestCase`
- Assert enqueued and performed jobs with `assert_enqueued_with` / `assert_performed_with`
- Rails 7.2+ defers `perform_later` until after the surrounding transaction commits. Inside a controller test wrapped in transactional fixtures, the enqueue happens at commit — use `assert_enqueued_jobs` around the request, or wrap setup in an explicit `ActiveRecord::Base.transaction { ... }` so commit fires. Jobs are dropped on rollback.
- Use `assert_enqueued_jobs n do ... end` for bulk enqueues (`perform_all_later`)

## Mailer Tests

- Place in `test/mailers/` and `test/mailers/previews/`, use `ActionMailer::TestCase`
- Assert subject, to/from, and body content
- Use `assert_emails` to assert delivery count

## Helper Tests

- Place in `test/helpers/`, use `ActionView::TestCase`
- Test custom view helpers in isolation

## Route Assertions

- Place inside controller or integration tests
- Use `assert_routing` and `assert_recognizes` for custom constraints

## Fixtures

- Store in `test/fixtures/<table>.yml`
- Reference associations by fixture label (not id)
- Use realistic, minimal data with proper associations

## Key Assertion Patterns

- `assert_difference "Model.count", +1 do ... end`
- `assert_no_difference "Model.count" do ... end`
- `assert_changes -> { record.reload.attr }, from: x, to: y do ... end`
- `assert_enqueued_with(job: MyJob, args: [...]) do ... end`
- `assert_emails 1 do ... end`
- `assert_raises ExceptionClass do ... end`

## Examples

## Model Test

```ruby
# test/models/post_test.rb
require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "title must be present" do
    post = Post.new(title: nil)
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "display_name falls back to email when name blank" do
    user = users(:john)
    user.update!(name: "")
    assert_equal user.email, user.display_name
  end

  test "destroys dependent posts when user destroyed" do
    user = users(:author)
    assert_difference "Post.count", -user.posts.count do
      user.destroy
    end
  end

  test "raises when saving duplicate email" do
    user = users(:one).dup
    assert_raises ActiveRecord::RecordInvalid do
      user.save!
    end
  end
end
```

## Controller Test

```ruby
# test/controllers/posts_controller_test.rb
require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:author)
    @post = posts(:published_post)
    sign_in @user
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should create post" do
    assert_difference -> { Post.count }, +1 do
      post posts_url, params: { post: { title: "Example", body: "Content" } }
    end
    assert_redirected_to Post.last
  end

  test "should not create post with invalid attributes" do
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should not allow editing other users posts" do
    get edit_post_path(posts(:other_user_post))
    assert_response :forbidden
  end

  test "should respond with turbo stream on create" do
    post posts_path, params: { post: { title: "New Post", body: "Content" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
  end
end
```

## Job Test

```ruby
# test/jobs/cleanup_job_test.rb
require "test_helper"

class CleanupJobTest < ActiveJob::TestCase
  test "job runs successfully" do
    assert_performed_with(job: CleanupJob) do
      CleanupJob.perform_later
    end
  end
end
```

## Mailer Test

```ruby
# test/mailers/user_mailer_test.rb
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome email" do
    email = UserMailer.welcome(users(:one))
    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [users(:one).email], email.to
    assert_match "Welcome", email.body.encoded
  end
end
```

## Helper Test

```ruby
# test/helpers/posts_helper_test.rb
require "test_helper"

class PostsHelperTest < ActionView::TestCase
  test "formatted title" do
    assert_equal "Title: Hello", format_title("Hello")
  end
end
```

## Route Assertion

```ruby
class CustomRoutesTest < ActionDispatch::IntegrationTest
  test "recognizes custom action" do
    assert_routing "/posts/1/preview", controller: "posts", action: "preview", id: "1"
  end
end
```

## State Change Assertions

```ruby
test "should update post status" do
  assert_changes -> { @post.reload.status }, from: "draft", to: "published" do
    @post.publish!
  end
end

test "should send welcome email after user creation" do
  assert_emails 1 do
    post users_path, params: { user: { name: "Test", email: "test@example.com" } }
  end
end
```

## Fixture File Examples

```yaml
# test/fixtures/users.yml
author:
  name: "John Author"
  email: "author@example.com"

editor:
  name: "Jane Editor"
  email: "editor@example.com"

# test/fixtures/posts.yml
published_post:
  title: "Published Post"
  body: "This is published"
  user: author
  published: true

draft_post:
  title: "Draft Post"
  body: "This is a draft"
  user: author
  published: false

other_user_post:
  title: "Other User Post"
  body: "Not my post"
  user: editor
  published: true
```
