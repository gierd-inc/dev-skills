# Migration Smells — Code Samples

## The smell — referencing app models

```ruby
class BackfillFlag < ActiveRecord::Migration[7.1]
  def up
    User.find_each { |u| u.update!(flag: true) }
  end
end
```
Six months from now `User` adds a required column or a callback that calls an external service — this migration breaks on a fresh DB.

## The fix — scoped anonymous class

```ruby
class BackfillFlag < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    user = Class.new(ActiveRecord::Base) { self.table_name = "users" }
    user.where(flag: nil).in_batches.update_all(flag: true)
  end

  def down
    # no-op; this is a one-way data fix
  end
end
```

## The smell — irreversible

```ruby
def change
  execute "UPDATE posts SET status = 'draft' WHERE status IS NULL"
end
```

## The fix — reversible / explicit up + down

```ruby
def change
  reversible do |dir|
    dir.up   { execute "UPDATE posts SET status = 'draft' WHERE status IS NULL" }
    dir.down { execute "UPDATE posts SET status = NULL  WHERE status = 'draft'" }
  end
end
```

## The smell — schema + slow data backfill mixed

```ruby
class AddCachedTotalToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :cached_total, :integer
    Order.find_each { |o| o.update_columns(cached_total: o.line_items.sum(:cents)) }
    change_column_null :orders, :cached_total, false
  end
end
```

## The fix — split into multiple migrations / steps

```ruby
# 1) Add the column nullable
class AddCachedTotalToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :cached_total, :integer
  end
end

# 2) Backfill in a separate deploy (rake task or migration with strong_migrations safe_by_default)
class BackfillCachedTotal < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    order = Class.new(ActiveRecord::Base) { self.table_name = "orders" }
    order.where(cached_total: nil).find_each do |o|
      o.update_columns(cached_total: o.connection.select_value(<<~SQL))
        SELECT COALESCE(SUM(cents), 0) FROM line_items WHERE order_id = #{o.id}
      SQL
    end
  end
end

# 3) After backfill is verified, enforce NOT NULL
class EnforceCachedTotalNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :orders, :cached_total, false
  end
end
```

## Foreign key with index

```ruby
add_reference :comments, :post, null: false, foreign_key: true
# index: true is the default in Rails 5+
```
