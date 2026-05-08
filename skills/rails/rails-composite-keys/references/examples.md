# Composite Keys Examples

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
