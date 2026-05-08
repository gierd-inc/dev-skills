# Anemic Domain Model — Code Samples

## The smell

```ruby
class Post < ApplicationRecord
  belongs_to :author
  validates :title, presence: true
  # ... no behavior
end

class PublishPostService
  def initialize(post); @post = post; end

  def call
    @post.published_at = Time.current
    @post.status = :published
    @post.save!
    NotifySubscribersJob.perform_later(@post)
  end
end

# Call site:
PublishPostService.new(@post).call
```

## The fix — behavior on the model

```ruby
class Post < ApplicationRecord
  belongs_to :author
  validates :title, presence: true

  scope :published, -> { where.not(published_at: nil) }

  def publish
    update!(published_at: Time.current, status: :published)
    NotifySubscribersJob.perform_later(self)
  end

  def published?
    published_at.present?
  end
end

# Call site:
@post.publish
```

## When extraction is warranted — name it as a noun

```ruby
# Operation spans Invoice, Payment, Account — no single owner
class PaymentReconciliation
  def initialize(account, period:)
    @account, @period = account, period
  end

  def perform
    # ...
  end
end

PaymentReconciliation.new(account, period: Date.current.all_month).perform
```
