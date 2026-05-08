# Active Support Examples

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
