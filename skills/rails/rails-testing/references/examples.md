# Rails Testing Examples

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
