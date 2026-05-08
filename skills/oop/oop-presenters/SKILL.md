---
name: oop-presenters
description: Use when view helpers are growing to handle display logic specific to one model, or when ERB has too many conditionals about how to format or label a model's state. Load when building presenters, decorators, or view objects that wrap AR models for display.
---

# Presenters

## What it is

A Presenter (sometimes called a Decorator or View Object) wraps a model and adds display-only logic: formatted strings, conditional CSS classes, labels for enum values, HTML-safe output. It lives in the view layer and keeps the model clean.

Presenters are a better home for display logic than:
- Fat view helpers (hard to discover, no OO)
- Model methods like `formatted_created_at` (models shouldn't know about display)
- ERB conditionals repeated across multiple views

## Would a fat model / helper do?

Use a helper if the formatting is generic and reused across many different models (e.g. `time_ago_in_words`). Keep it on the model if it's about domain state, not display. Extract a presenter when:

- A model has 3+ display-only methods (formatted dates, label strings, CSS classes)
- The same model is displayed differently in different contexts (list vs. detail view)
- Your helper module for one model is growing past 20 lines

## When NOT to

- When a helper method is truly generic and not model-specific
- When there's only one display method — add it to the helper
- When the display logic is simple enough to inline in ERB with a ternary

## Shape

```ruby
# app/presenters/order_presenter.rb
class OrderPresenter < SimpleDelegator
  def status_label
    case status
    when "pending"   then "Awaiting payment"
    when "paid"      then "Paid"
    when "shipped"   then "Shipped"
    when "cancelled" then "Cancelled"
    end
  end

  def status_badge_class
    case status
    when "pending"   then "badge-warning"
    when "paid"      then "badge-success"
    when "shipped"   then "badge-info"
    when "cancelled" then "badge-error"
    end
  end

  def formatted_total
    helpers.number_to_currency(total_cents / 100.0)
  end

  def shipped_or_pending
    shipped? ? "Shipped #{shipped_at.strftime('%b %-d')}" : "Pending"
  end
end
```

## `SimpleDelegator` vs plain Ruby

- **`SimpleDelegator`** — delegates all unknown methods to the wrapped object automatically. Use when the presenter needs to behave like the model in views (e.g., for `form_with(model:)` or URL helpers like `order_path(order)`).
- **Plain Ruby** — explicit delegation only. Use when you want to control the interface and don't want the full AR model interface leaking through.

## Naming & location

- `app/presenters/order_presenter.rb` → `OrderPresenter`
- `app/presenters/users/profile_presenter.rb` → `Users::ProfilePresenter` (for context-specific views)
- Always name as `ModelPresenter` or `Model::ContextPresenter`
- No `*Decorator` suffix unless using a gem (Draper) that establishes that convention

## Instantiating in controllers

```ruby
class OrdersController < ApplicationController
  def show
    @order = OrderPresenter.new(Order.find(params[:id]))
  end
end
```

Or use a helper method in the base controller:

```ruby
def present(object, presenter_class = nil)
  presenter_class ||= "#{object.class}Presenter".constantize
  presenter_class.new(object)
end
```

## Accessing view helpers in a presenter

`SimpleDelegator` doesn't have access to `h` / `helpers` automatically. Options:

```ruby
# Option 1: pass helpers on initialization
class OrderPresenter < SimpleDelegator
  def initialize(order, view_context)
    super(order)
    @view_context = view_context
  end

  def formatted_total
    @view_context.number_to_currency(total_cents / 100.0)
  end
end

# Option 2: keep formatting methods that don't need view helpers as plain strings
# and use helpers only in the view for Rails-specific formatting
```

## Testing (Minitest)

```ruby
# test/presenters/order_presenter_test.rb
class OrderPresenterTest < ActiveSupport::TestCase
  setup do
    @order = orders(:pending)
    @presenter = OrderPresenter.new(@order)
  end

  test "status_label for pending order" do
    assert_equal "Awaiting payment", @presenter.status_label
  end

  test "still delegates AR methods to the model" do
    assert_equal @order.id, @presenter.id
    assert_equal @order.total_cents, @presenter.total_cents
  end

  test "can be used in URL helpers (responds to to_param)" do
    assert_equal @order.to_param, @presenter.to_param
  end
end
```

## Common smells

- **Presenter with database calls** — presenters are for display only; if you need related records, eager-load them in the controller
- **Presenter used in models** — a model should never depend on a presenter; the dependency is one-way
- **Presenter that duplicates the model** — if the presenter adds no display logic, it's dead code
- **Presenter in the wrong layer** — never instantiate presenters inside models, jobs, or mailers

## See also

- [oop-value-objects](../oop-value-objects/SKILL.md) — for values that need display formatting but also carry behavior
- [oop-form-objects](../oop-form-objects/SKILL.md) — the write-side complement to presenters
- [rails-helpers](../../rails/rails-helpers/SKILL.md) — Rails view helpers, the simpler alternative for generic formatting
- [rails-views](../../rails/rails-views/SKILL.md) — ERB templates and where display logic should live

See `references/examples.md` for annotated code samples.
