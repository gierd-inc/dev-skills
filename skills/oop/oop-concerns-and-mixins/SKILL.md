---
name: oop-concerns-and-mixins
description: Use when 2+ models (or controllers) share the same behavior and you want to extract it cleanly. Load when working with `ActiveSupport::Concern`, module inclusion, `included do`, `class_methods`, or debugging unexpected method resolution order.
---

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

- [oop-presenters](../oop-presenters/SKILL.md) — for view-layer behavior (don't put display logic in a model concern)
- [oop-service-objects](../oop-service-objects/SKILL.md) — for cross-model operations that don't belong on any one model
- [rails-models](../../rails/rails-models/SKILL.md) — method naming, callback rules, and organization conventions
- [rails-antipatterns/fat-model-god-object](../../rails-antipatterns/rails-antipattern-fat-model-god-object/SKILL.md) — the antipattern concerns are meant to fix

See `references/examples.md` for annotated code samples.
