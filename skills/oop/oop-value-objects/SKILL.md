---
name: oop-value-objects
description: Use when you need to encapsulate a value with behavior — currency, email addresses, geographic coordinates, phone numbers, date ranges. Load when working with `composed_of`, custom attribute types, or when you find yourself duplicating formatting/validation logic across models for the same domain value.
---

# Value Objects

## What it is

A Value Object encapsulates a value (or small group of related values) along with the behavior that belongs to it. Two instances are equal if their values are equal — identity doesn't matter. They are immutable: once created, they don't change.

Classic examples: `Money`, `Email`, `PhoneNumber`, `Coordinate`, `DateRange`, `Color`.

## Would a fat model do?

Before extracting a value object, ask: is this value used in more than one model, or does it carry meaningful behavior beyond simple formatting? If it's just a string that lives in one model with one display helper, keep it in the model. Extract when:

- The same domain value (e.g. currency amounts) appears in multiple models with the same logic
- The value needs validation, formatting, arithmetic, or comparison that doesn't belong on the model itself
- You're writing the same `formatted_amount` / `amount_in_cents` helper in three places

## When NOT to

- Simple scalar wrapper with no behavior — just use the raw attribute
- One-off formatting: a view helper is simpler and less infrastructure
- If the value is only ever used in one model with one or two methods — put the methods on the model first

## Shape

```ruby
class Money
  include Comparable

  attr_reader :amount, :currency

  def initialize(amount, currency = "USD")
    @amount = amount.to_d
    @currency = currency.upcase.freeze
    freeze
  end

  def +(other)
    raise ArgumentError, "Currency mismatch" unless currency == other.currency
    Money.new(amount + other.amount, currency)
  end

  def <=>(other)
    return nil unless currency == other.currency
    amount <=> other.amount
  end

  def to_s
    "#{currency} #{format('%.2f', amount)}"
  end

  def ==(other)
    other.is_a?(Money) && amount == other.amount && currency == other.currency
  end
end
```

## Naming & location

- Files live in `app/values/` (`app/values/money.rb`, `app/values/email_address.rb`)
- Class names are nouns in the domain: `Money`, `EmailAddress`, `Coordinate`, `DateRange`
- No `*ValueObject` suffix — the concept is in the location and interface

## Composing into Active Record

**Option 1 — `composed_of` (classic Rails):**

```ruby
class Order < ApplicationRecord
  composed_of :total,
    class_name: "Money",
    mapping: [%w[total_amount amount], %w[total_currency currency]]
end
```

**Option 2 — Custom attribute type (Rails 7+, preferred for serialization control):**

```ruby
class MoneyType < ActiveRecord::Type::Value
  def cast(value)
    return value if value.is_a?(Money)
    Money.new(value) if value
  end
  # serialize/deserialize as needed
end

# In an initializer:
ActiveRecord::Type.register(:money, MoneyType)

# In the model:
class Order < ApplicationRecord
  attribute :total, :money
end
```

## Testing (Minitest)

Value objects are plain Ruby — test them in isolation without loading Rails:

```ruby
class MoneyTest < ActiveSupport::TestCase
  test "equality by value, not identity" do
    assert Money.new(10, "USD") == Money.new(10, "USD")
    refute Money.new(10, "USD").equal?(Money.new(10, "USD"))
  end

  test "addition" do
    result = Money.new(5, "USD") + Money.new(3, "USD")
    assert_equal Money.new(8, "USD"), result
  end

  test "currency mismatch raises" do
    assert_raises(ArgumentError) { Money.new(5, "USD") + Money.new(5, "EUR") }
  end

  test "immutable" do
    m = Money.new(10)
    assert_raises(FrozenError) { m.instance_variable_set(:@amount, 99) }
  end
end
```

## Common smells

- **Mutable value object** — call `freeze` in `initialize`; value objects must be immutable
- **Value object doing persistence** — value objects don't save themselves; compose them into an AR model
- **Anemic value object** — if it has no methods beyond readers, it's just a Struct; use `Data.define` (Ruby 3.2+) or a simple `Struct`
- **Too many responsibilities** — a `Money` that also handles exchange rates has grown into a service; split it

## See also

- [oop-null-objects](../oop-null-objects/SKILL.md) — null variant of a value object (safe defaults, no nil checks)
- [rails-models](../../rails/rails-models/SKILL.md) — `composed_of` and attribute types on AR models
- [rails-the-rails-way](../../rails/rails-the-rails-way/SKILL.md) — fat model defaults before extracting

See `references/examples.md` for annotated code samples.
