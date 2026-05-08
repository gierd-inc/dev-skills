# Mock-Heavy Tests — Code Samples

## The smell

```ruby
test "publishing a post notifies subscribers" do
  post       = mock("post", id: 1, subscribers: [mock("sub", email: "a@b.com")])
  mailer     = mock("mailer")
  job_class  = class_double(NotifySubscribersJob)
  publisher  = Publisher.new(mailer: mailer, job_class: job_class)

  mailer.expects(:notify).with(post)
  job_class.expects(:perform_later).with(post)

  publisher.call(post)
end
```

## The fix — fixture-first, real objects

```ruby
# test/models/post_test.rb
require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "publish marks the post as published and notifies subscribers" do
    post = posts(:draft)

    assert_emails 1 do
      assert_enqueued_with(job: NotifySubscribersJob, args: [post]) do
        post.publish
      end
    end

    assert post.published?
    assert_not_nil post.published_at
  end
end
```

## Stub only at the boundary

```ruby
class StripeWebhookTest < ActiveSupport::TestCase
  test "ignores untrusted signatures" do
    Stripe::Webhook.stub(:construct_event, ->(*) { raise Stripe::SignatureVerificationError }) do
      post stripe_webhooks_path, params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "bad" }
      assert_response :bad_request
    end
  end
end
```

```ruby
# Time
test "trial expires after 30 days" do
  user = users(:trialing)
  travel_to user.trial_started_at + 31.days do
    assert user.trial_expired?
  end
end
```
