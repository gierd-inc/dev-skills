# Concerns & Mixins Examples

## Archivable concern

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

## Auditable concern (tracks creator/updater)

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

## Controller concern (rate limiting)

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

## Combining multiple concerns

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

## Debugging method resolution

```ruby
# In a console: see exactly where each method comes from
Post.ancestors
# => [Post, Publishable, Archivable, Auditable, ApplicationRecord, ...]

# Find which module defines a method:
Post.instance_method(:publish).source_location
# => [".../app/models/concerns/publishable.rb", 10]
```

## Minitest: testing via a real model

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
