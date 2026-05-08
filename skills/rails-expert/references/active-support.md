# Rails Active Support

## CurrentAttributes

- Use `Current` to store per-request data like user, account, or timezone
- Do not store mutable state across threads or background jobs
- Always reset `Current` at the beginning of a request
- Declare attributes with `attribute :user, :account` inside the class

## Core Extensions

- Prefer Rails-provided core extensions over monkey-patching
- Place any custom extensions under `config/initializers/core_ext/`
- Avoid reopening core classes in libraries or gems

## Concerns

- Use `ActiveSupport::Concern` to modularize cross-cutting behaviors
- Use `included do ... end` for class-level hooks
- Include concerns in models or controllers as needed

## Serialization (MessagePack)

- Prefer `ActiveSupport::MessagePack` over JSON/Marshal for cookies and cache: smaller, faster, supports Ruby types (Time, Symbol, BigDecimal)
- `config.active_support.message_serializer = :message_pack`
- `config.action_dispatch.cookies_serializer = :message_pack`
- `config.cache_store = :file_store, "tmp/cache", { serializer: :message_pack }`

## Deprecators Registry

- Register gem/engine deprecators with `Rails.application.deprecators[:my_gem] = ActiveSupport::Deprecation.new("2.0", "MyGem")`
- Lookup via `Rails.application.deprecators[:my_gem].warn(...)`
- `Rails.application.deprecators.silence { ... }` silences all registered deprecators at once

## Instrumentation

- Use `ActiveSupport::Notifications.instrument("group.event")` for observability
- Name events with dot notation and avoid generic terms
- Subscribe using `ActiveSupport::Notifications.subscribe("event.name")`
- Ensure payloads are JSON-serializable; avoid leaking sensitive data
- Only instrument where observability is genuinely valuable

## Examples

## CurrentAttributes

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account
end

# app/controllers/application_controller.rb
before_action do
  Current.user = current_user
end
```

## Core Extensions

```ruby
# config/initializers/core_ext/array.rb
class Array
  def to_sentence_and
    case length
    when 0 then ""
    when 1 then first.to_s
    when 2 then "#{first} and #{last}"
    else
      "#{self[0...-1].join(', ')}, and #{last}"
    end
  end
end
```

## Instrumentation

```ruby
# Around expensive method
ActiveSupport::Notifications.instrument("user.login") do
  login(user)
end

# Subscription handler
ActiveSupport::Notifications.subscribe("user.login") do |name, start, finish, id, payload|
  Rails.logger.info("Login took #{finish - start} seconds")
end
```

## Notifications with Payload

```ruby
def process_payment(user, amount)
  instrument("payment.processed", user_id: user.id, amount:) do
    PaymentService.charge(user, amount)
  end
end
```

## Concern-Based Extension

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create -> { audit!("created") }
  end

  def audit!(event)
    Rails.logger.info("#{event} #{self.class.name} with ID=#{id}")
  end
end

# app/models/invoice.rb
class Invoice < ApplicationRecord
  include Auditable
end
```
