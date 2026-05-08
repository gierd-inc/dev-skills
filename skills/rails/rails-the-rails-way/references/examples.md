# Rails Way — Code Samples

## RDoc-Style Method Comments

```ruby
## Calculates the user's full name, falling back to email if blank
# @return [String] user-facing name
def display_name
  name.presence || email
end
```

## Concern Structure

```ruby
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(published: true) }
    scope :draft, -> { where(published: false) }
  end

  def publish!
    update!(published: true)
  end

  def published?
    published
  end
end
```

## Controller Configuration Order

```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rejection :too_many_requests }

  before_action :ensure_user_exists, only: :new
end
```

## Strong Params (Modern)

```ruby
def user_params
  params.expect(user: [:email, :name])
end
```
