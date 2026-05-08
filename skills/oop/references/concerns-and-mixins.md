# Concerns & Mixins

## What it is

A Concern is a module (backed by `ActiveSupport::Concern`) that encapsulates a reusable chunk of model or controller behavior — validations, scopes, callbacks, instance methods — and mixes it in. Concerns are the Rails-idiomatic alternative to deep inheritance chains.

Concerns are **composition**, not extraction. Don't reach for them to shrink a fat model; reach for them when the same behavior genuinely belongs to multiple models.

## Would a fat model do?

Keep behavior on the model until:

- 2+ models share identical validations, scopes, or instance methods
- The shared behavior forms a coherent capability (e.g. "can be published", "can be archived")
- The module name reads as an **adjective** describing what the model *is able to do*: `Publishable`, `Archivable`, `Taggable`, `Searchable`

If only one model uses it, it's not a concern — it's just a private section of the model.

## When NOT to

- Splitting a single model into multiple concerns just to keep file size down — this is the "God Module" antipattern disguised as organization
- Sharing behavior that differs between models (conditional logic inside the concern is a red flag)
- When a value object or query object is the right fit (concerns are for behavior on the model, not for query logic)

## Shape

```ruby
# app/models/concerns/publishable.rb
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where.not(published_at: nil) }
    scope :unpublished, -> { where(published_at: nil) }
  end

  def publish
    update!(published_at: Time.current)
  end

  def unpublish
    update!(published_at: nil)
  end

  def published?
    published_at.present?
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  include Publishable
end

# app/models/page.rb
class Page < ApplicationRecord
  include Publishable
end
```

## `class_methods` block

Use `class_methods` (not `def self.method_name`) to define class-level methods inside a concern:

```ruby
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable
    has_many :tags, through: :taggings
  end

  class_methods do
    def tagged_with(name)
      joins(:tags).where(tags: { name: name })
    end
  end

  def tag_list
    tags.map(&:name).join(", ")
  end
end
```

## Naming & location

- Model concerns: `app/models/concerns/publishable.rb` → `module Publishable`
- Controller concerns: `app/controllers/concerns/rate_limitable.rb` → `module RateLimitable`
- Name with adjectives or present-participials: `Archivable`, `Trackable`, `Searchable`, `Auditable`
- Avoid `*able` when it doesn't fit — `Locatable`, `Expirable`, `Billable` all work; `Postable` is confusing

## Testing (Minitest)

Test the concern through the models that include it (or a minimal test model):

```ruby
# test/models/concerns/publishable_test.rb
class PublishableTest < ActiveSupport::TestCase
  # Use a real model that includes it
  setup { @post = posts(:draft) }

  test "publish sets published_at" do
    assert_nil @post.published_at
    @post.publish
    assert_not_nil @post.published_at
  end

  test "published? reflects state" do
    refute @post.published?
    @post.publish
    assert @post.published?
  end

  test "published scope returns published records" do
    @post.publish
    assert_includes Post.published, @post
  end
end
```

## Common smells

- **Concern that only one model includes** — not a concern, just code on the model
- **Concern with `if model_is_a_post?` branching** — behavior that differs per model is not shared behavior
- **Dumping ground concern** — `Utilities` or `Helpers` modules that grow with unrelated methods
- **Deeply nested dependency** — `include A` which `include B` which `include C`. Debug with `Model.ancestors`
- **Hidden state mutations** — callbacks inside concerns that fire unexpectedly on save; keep concerns transparent about what they hook

## See also

- [presenters.md](./presenters.md) — for view-layer behavior (don't put display logic in a model concern)
- [service-objects.md](./service-objects.md) — for cross-model operations that don't belong on any one model
- [rails-models](../../rails/rails-models/SKILL.md) — method naming, callback rules, and organization conventions
- [rails-antipatterns/fat-model-god-object](../../rails-antipatterns/rails-antipattern-fat-model-god-object/SKILL.md) — the antipattern concerns are meant to fix

## Examples

### Archivable concern

```ruby
# app/models/concerns/archivable.rb
module Archivable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }

    default_scope { active }
  end

  def archive
    update!(archived_at: Time.current)
  end

  def unarchive
    update!(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end
end
```

### Auditable concern (tracks creator/updater)

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: "User", optional: true
    belongs_to :updated_by, class_name: "User", optional: true

    before_create { self.created_by ||= Current.user }
    before_save   { self.updated_by = Current.user }
  end
end
```

### Controller concern (rate limiting)

```ruby
# app/controllers/concerns/rate_limitable.rb
module RateLimitable
  extend ActiveSupport::Concern

  included do
    before_action :check_rate_limit, only: %i[create update]
  end

  private

  def check_rate_limit
    rate_limit(to: 10, within: 1.minute) do
      render json: { error: "Too many requests" }, status: :too_many_requests
    end
  end
end

# app/controllers/api/messages_controller.rb
class Api::MessagesController < Api::BaseController
  include RateLimitable
end
```

### Combining multiple concerns

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include Publishable
  include Archivable
  include Auditable
  include Taggable

  # Model's own validations and associations:
  belongs_to :author, class_name: "User"
  validates :title, presence: true, length: { maximum: 200 }
end
```

### Debugging method resolution

```ruby
# In a console: see exactly where each method comes from
Post.ancestors
# => [Post, Publishable, Archivable, Auditable, ApplicationRecord, ...]

# Find which module defines a method:
Post.instance_method(:publish).source_location
# => [".../app/models/concerns/publishable.rb", 10]
```

### Minitest: testing via a real model

```ruby
# test/models/concerns/archivable_test.rb
class ArchivableTest < ActiveSupport::TestCase
  setup { @post = posts(:published) }

  test "archive sets archived_at" do
    @post.archive
    assert_not_nil @post.archived_at
  end

  test "archived? follows archived_at" do
    refute @post.archived?
    @post.archive
    assert @post.archived?
  end

  test "active scope excludes archived records" do
    @post.archive
    refute_includes Post.active, @post
  end
end
```
