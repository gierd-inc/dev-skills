# Rails Composite Keys

## When to Use

- Use composite primary keys when uniqueness must span multiple columns
- Avoid them unless your data model or legacy database demands it

## Migrations

- Use `primary_key: %i[key1 key2]` when creating the table
- Do not use `t.primary_key :id` — Rails will create a single-column ID instead
- Omit `id: false` when using the `primary_key:` option directly on `create_table`

## Model Declarations

- Rails 7.1+ ships native composite keys — no gem required
- Use `self.primary_key = [:user_id, :group_id]` on the model
- For non-PK composite identity (e.g. tenant-scoped records with surrogate `id`), use `query_constraints :tenant_id, :id` so all generated SQL scopes by the full tuple

## Associations

- Use `belongs_to :owner, query_constraints: [:tenant_id, :owner_id]` so AR matches the parent on both columns
- `has_many :memberships, query_constraints: [:tenant_id, :id]` on the inverse side
- Foreign keys must match the composite declaration; explicit `foreign_key: [:user_id, :group_id]` still works
- Avoid polymorphic associations with composite keys

## Querying

- Use arrays in `find`: `Membership.find([user_id, group_id])`
- Use `where(user_id: 1, group_id: 2)` for scoped queries
- Composite keys don't support `find_by(id: ...)` unless `id` is virtualized

## Warnings

- `url_for` and `form_with` helpers may need custom routing
- Eager loading may not optimize correctly
- Test thoroughly with system and integration tests

## Examples

## Migration

```ruby
# db/migrate/20240705000000_create_memberships.rb
class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships, primary_key: %i[user_id team_id] do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.datetime :joined_at
      t.timestamps
    end
  end
end
```

## Model Declaration

```ruby
# app/models/membership.rb
class Membership < ApplicationRecord
  self.primary_key = [:user_id, :team_id]

  belongs_to :user
  belongs_to :team
end
```

## query_constraints (composite identity without changing the PK)

```ruby
# Tenant-scoped records: surrogate `id` + `tenant_id` form the logical key
class Order < ApplicationRecord
  query_constraints :tenant_id, :id

  belongs_to :customer, query_constraints: [:tenant_id, :customer_id]
end

class Customer < ApplicationRecord
  query_constraints :tenant_id, :id

  has_many :orders, query_constraints: [:tenant_id, :id]
end
```

## Association with Composite Keys

```ruby
# app/models/team.rb
class Team < ApplicationRecord
  has_many :memberships, foreign_key: [:team_id]
  has_many :users, through: :memberships
end
```

## Querying with Composite Keys

```ruby
# app/controllers/memberships_controller.rb
class MembershipsController < ApplicationController
  def show
    @membership = Membership.find([params[:user_id], params[:team_id]])
  end
end
```

```ruby
# Scoped where clause
Membership.where(user_id: 1, group_id: 2)
```
