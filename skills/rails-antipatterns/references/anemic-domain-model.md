# Antipattern: Anemic Domain Model

## The smell
- Models containing only validations, associations, and scopes — no verbs
- `app/services/` full of `*Service` / `*UseCase` classes that orchestrate model attribute changes
- "Where does X happen?" → "search `services/`"
- Tests stub the services rather than exercising the models

## Why it hurts
- Behavior is hard to discover — readers have to know the service exists
- Conditional dispatch creeps into services because models can't answer questions about themselves
- Every new verb is a new class with `#call`, plus a spec, plus wiring
- Encourages procedural style; weakens domain reasoning

## The fix
- **Put behavior on the model.** A `Post` should know how to publish itself
- Extract a **concern** if the behavior has its own cluster of methods
- Extract a **PORO named as a noun** (`PostPublication`) — but the entry point stays on the model
- This is core to the 37signals/DHH style: `post.publish`, not `PublishPostService.call(post)`

## When it's actually fine
A class is genuinely warranted when an operation spans multiple aggregates and doesn't naturally belong to any one model. Even then, name it as a **noun** (`PaymentReconciliation`), not `*Service`.

## See also
- Rails models reference: `../../rails/references/models.md`
- [service-object-soup](service-object-soup.md)
- [fat-model-god-object](fat-model-god-object.md)

## Examples

### The smell

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

### The fix — behavior on the model

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

### When extraction is warranted — name it as a noun

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
