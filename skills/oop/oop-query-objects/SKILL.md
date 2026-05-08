---
name: oop-query-objects
description: Use when an ActiveRecord scope has outgrown a single method — complex joins, multi-step filtering, reusable filter+sort+paginate pipelines. Load when building query classes, encapsulating report queries, or fixing spaghetti SQL in controllers and scopes.
---

# Query Objects

## What it is

A Query Object encapsulates a complex or reusable database query in a plain Ruby class. It accepts filters/parameters, builds an ActiveRecord relation, and returns it — staying composable with other scopes and relations.

Query objects are the right home for:
- Multi-join, multi-filter queries that don't belong to a single scope
- Report or analytics queries (aggregations, groupings)
- Filter pipelines (search + sort + paginate with many optional params)

## Would a scope do?

Scopes are the default. Extract a query object when:

- A scope exceeds ~10 lines or chains 5+ conditions
- The query needs to accept many optional parameters (a filter form's params)
- The same complex join is copied across multiple scopes
- You're building a query that aggregates across models with no natural owner

Keep it as a scope if: it's one condition, it's chainable and composable with existing scopes, and it doesn't need constructor parameters beyond one argument.

## When NOT to

- Simple, single-condition scopes: `scope :active, -> { where(active: true) }` — stay on the model
- Queries that already compose cleanly from existing scopes: `Order.paid.recent.limit(10)` — no need to extract
- Filtering that belongs to search (use a search library like `ransack` or `pg_search` instead)

## Shape

```ruby
# app/queries/orders/recent_for_customer.rb
module Orders
  class RecentForCustomer
    def initialize(customer:, limit: 10)
      @customer = customer
      @limit = limit
    end

    def call
      Order
        .where(customer: @customer)
        .paid
        .includes(:line_items, :shipping_address)
        .order(created_at: :desc)
        .limit(@limit)
    end
  end
end

# Usage:
Orders::RecentForCustomer.new(customer: current_user, limit: 5).call
```

## Filter pipeline pattern

For a filter form with many optional params:

```ruby
# app/queries/project_filter.rb
class ProjectFilter
  def initialize(params:, base_scope: Project.all)
    @params = params
    @scope = base_scope
  end

  def call
    filter_by_status
    filter_by_owner
    sort
    @scope
  end

  private

  def filter_by_status
    return unless @params[:status].present?
    @scope = @scope.where(status: @params[:status])
  end

  def filter_by_owner
    return unless @params[:owner_id].present?
    @scope = @scope.where(owner_id: @params[:owner_id])
  end

  def sort
    column = %w[name created_at updated_at].include?(@params[:sort]) ? @params[:sort] : "created_at"
    direction = @params[:direction] == "asc" ? :asc : :desc
    @scope = @scope.order(column => direction)
  end
end

# Usage in controller:
@projects = ProjectFilter.new(params: filter_params).call.page(params[:page])
```

## Naming & location

- `app/queries/<model_plural>/<action>.rb` for single-use queries: `app/queries/orders/overdue.rb`
- `app/queries/<model_singular>_filter.rb` for filter pipelines: `app/queries/project_filter.rb`
- Class names describe what the query does, not the SQL: `Orders::Overdue`, `RecentForCustomer`, `ProjectFilter`
- Avoid `*Query` suffix unless it aids discovery in a large codebase

## Testing (Minitest)

Query objects are plain Ruby — test against the database with fixtures:

```ruby
# test/queries/orders/recent_for_customer_test.rb
class Orders::RecentForCustomerTest < ActiveSupport::TestCase
  test "returns only the customer's orders" do
    customer = users(:ryan)
    other_orders = orders(:other_customer)
    result = Orders::RecentForCustomer.new(customer: customer).call

    assert_includes result, orders(:paid_order)
    refute_includes result, other_orders
  end

  test "respects limit" do
    customer = users(:ryan)
    result = Orders::RecentForCustomer.new(customer: customer, limit: 1).call
    assert_equal 1, result.size
  end

  test "returns an AR relation (chainable)" do
    result = Orders::RecentForCustomer.new(customer: users(:ryan)).call
    assert result.is_a?(ActiveRecord::Relation)
  end
end
```

## Common smells

- **Query object that returns models instead of a relation** — returning an `Array` breaks chaining; always return `ActiveRecord::Relation` unless aggregating
- **Query object with business logic** — if it's deciding *what to do* with results (not just *what to fetch*), it's grown into a service object
- **Query object called from a model scope** — fine for reuse, but don't make the model depend on the query object; pass the scope in as a parameter
- **One query object per action in the controller** — you're rebuilding controllers with extra steps; scopes and simple model queries handle most cases

## See also

- [oop-service-objects](../oop-service-objects/SKILL.md) — when the operation does more than query (creates, sends, transforms)
- [oop-form-objects](../oop-form-objects/SKILL.md) — the form that submits filter params to a query object
- [rails-models](../../rails/rails-models/SKILL.md) — scopes: the default before extracting a query object
- [rails-antipatterns/spaghetti-sql](../../rails-antipatterns/rails-antipattern-spaghetti-sql/SKILL.md) — the problem query objects solve

See `references/examples.md` for annotated code samples.
