# Value Object Examples

## EmailAddress

```ruby
# app/values/email_address.rb
class EmailAddress
  PATTERN = /\A[^@\s]+@[^@\s]+\z/

  attr_reader :value

  def initialize(value)
    @value = value.to_s.strip.downcase.freeze
    freeze
  end

  def valid?
    value.match?(PATTERN)
  end

  def domain
    value.split("@").last
  end

  def to_s
    value
  end

  def ==(other)
    other.is_a?(EmailAddress) && value == other.value
  end

  alias eql? ==

  def hash
    value.hash
  end
end
```

## DateRange (Ruby 3.2+ Data class)

```ruby
# app/values/date_range.rb
# Data.define creates an immutable value type automatically
DateRange = Data.define(:starts_on, :ends_on) do
  def duration_days
    (ends_on - starts_on).to_i
  end

  def include?(date)
    (starts_on..ends_on).cover?(date)
  end

  def overlap?(other)
    starts_on <= other.ends_on && ends_on >= other.starts_on
  end

  def to_s
    "#{starts_on} – #{ends_on}"
  end
end

# Usage:
period = DateRange.new(starts_on: Date.today, ends_on: Date.today + 7)
period.duration_days  # => 7
period.include?(Date.today + 3)  # => true
```

## Composed into Active Record via `composed_of`

```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  composed_of :billing_period,
    class_name: "DateRange",
    mapping: [%w[starts_on starts_on], %w[ends_on ends_on]]

  # Now:
  # sub.billing_period.duration_days
  # sub.billing_period.include?(Date.today)
end
```

## Custom attribute type (Rails 7+)

```ruby
# app/types/email_address_type.rb
class EmailAddressType < ActiveRecord::Type::String
  def cast(value)
    return value if value.is_a?(EmailAddress)
    EmailAddress.new(value) if value.present?
  end

  def serialize(value)
    value.is_a?(EmailAddress) ? value.to_s : value
  end
end

# config/initializers/types.rb
ActiveRecord::Type.register(:email_address, EmailAddressType)

# app/models/user.rb
class User < ApplicationRecord
  attribute :email, :email_address

  validates :email, presence: true
  validate :email_format

  private

  def email_format
    errors.add(:email, :invalid) unless email&.valid?
  end
end
```

## Minitest

```ruby
# test/values/email_address_test.rb
require "test_helper"

class EmailAddressTest < ActiveSupport::TestCase
  test "normalizes to lowercase" do
    assert_equal "ryan@example.com", EmailAddress.new("RYAN@EXAMPLE.COM").to_s
  end

  test "valid? returns true for well-formed addresses" do
    assert EmailAddress.new("ryan@example.com").valid?
  end

  test "valid? returns false for malformed addresses" do
    refute EmailAddress.new("not-an-email").valid?
  end

  test "equality by value" do
    assert EmailAddress.new("a@b.com") == EmailAddress.new("a@b.com")
  end

  test "usable as hash key" do
    h = { EmailAddress.new("a@b.com") => 1 }
    assert_equal 1, h[EmailAddress.new("a@b.com")]
  end
end
```
