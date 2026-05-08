# Query Object Examples

## Report query with aggregation

```ruby
# app/queries/revenue_by_month.rb
class RevenueByMonth
  def initialize(year:)
    @year = year
  end

  def call
    Order
      .paid
      .where(paid_at: Date.new(@year).beginning_of_year..Date.new(@year).end_of_year)
      .group("DATE_TRUNC('month', paid_at)")
      .order("1")
      .sum(:total_cents)
      .transform_keys { |k| k.strftime("%B") }
      .transform_values { |v| v / 100.0 }
  end
end

# Usage:
RevenueByMonth.new(year: 2025).call
# => {"January" => 12450.00, "February" => 9870.00, ...}
```

## Full filter pipeline with Pagy

```ruby
# app/queries/user_filter.rb
class UserFilter
  SORTABLE_COLUMNS = %w[name email created_at last_sign_in_at].freeze
  VALID_ROLES = %w[admin member].freeze

  def initialize(params:, base_scope: User.all)
    @params = params.to_h.with_indifferent_access
    @scope = base_scope
  end

  def call
    apply_search
    apply_role
    apply_verified
    apply_sort
    @scope
  end

  private

  def apply_search
    return unless @params[:q].present?
    term = "%#{@params[:q].downcase}%"
    @scope = @scope.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ?", term, term)
  end

  def apply_role
    return unless VALID_ROLES.include?(@params[:role])
    @scope = @scope.where(role: @params[:role])
  end

  def apply_verified
    return if @params[:verified].blank?
    @scope = @params[:verified] == "true" ? @scope.verified : @scope.unverified
  end

  def apply_sort
    col = SORTABLE_COLUMNS.include?(@params[:sort]) ? @params[:sort] : "name"
    dir = @params[:direction] == "desc" ? :desc : :asc
    @scope = @scope.order(col => dir)
  end
end
```

## Controller usage with Pagy

```ruby
# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::BaseController
  def index
    base = UserFilter.new(params: filter_params).call
    @pagy, @users = pagy(base)
  end

  private

  def filter_params
    params.permit(:q, :role, :verified, :sort, :direction)
  end
end
```

## Composing a query object with a model scope

```ruby
# The query object accepts a base scope — can narrow an existing scope:
scope = Project.for_team(current_team)   # AR scope on model
ProjectFilter.new(params: filter_params, base_scope: scope).call
```

## Minitest for the filter pipeline

```ruby
# test/queries/user_filter_test.rb
class UserFilterTest < ActiveSupport::TestCase
  test "returns all users with no params" do
    result = UserFilter.new(params: {}).call
    assert_includes result, users(:ryan)
    assert_includes result, users(:guest_user)
  end

  test "filters by role" do
    result = UserFilter.new(params: { role: "admin" }).call
    assert_includes result, users(:ryan)
    refute_includes result, users(:guest_user)
  end

  test "search filters by name" do
    result = UserFilter.new(params: { q: "ryan" }).call
    assert_includes result, users(:ryan)
    refute_includes result, users(:guest_user)
  end

  test "returns AR relation for chaining" do
    assert_kind_of ActiveRecord::Relation, UserFilter.new(params: {}).call
  end

  test "ignores invalid sort columns" do
    # Should not raise, should fall back to name
    assert_nothing_raised { UserFilter.new(params: { sort: "DROP TABLE users" }).call.to_a }
  end
end
```
