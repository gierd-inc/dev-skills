# Rails Mailbox — Code Examples

## Routing Configuration

```ruby
# app/mailboxes/application_mailbox.rb
class ApplicationMailbox < ActionMailbox::Base
  routing /inbox@/i => :inbox
  routing /support\+(.+)@example\.com/i => :support
end
```

## Basic Mailbox Implementation

```ruby
# app/mailboxes/support_mailbox.rb
class SupportMailbox < ApplicationMailbox
  def receive
    user = User.find_by(email: mail.from.first)
    return unless user

    user.support_tickets.create!(body: mail.decoded)
  end
end
```

## Secure Processing with Sanitization

```ruby
# app/mailboxes/feedback_mailbox.rb
class FeedbackMailbox < ApplicationMailbox
  def receive
    body = sanitize(mail.decoded)
    Feedback.create!(email: mail.from.first, message: body)
  end

  private

  def sanitize(content)
    ActionController::Base.helpers.sanitize(content)
  end
end
```
