# Rails Migrations

## General Guidelines

- Always use `ActiveRecord::Migration[8.1]` or current version
- Use `null: false` on columns and references unless explicitly optional
- Use `change` method unless up/down is required for reversibility
- Prefer `schema.rb` for structure dumps unless using PostgreSQL + raw SQL

## Column Rules

- Use `string` type for enums, never `integer`
- Add an explicit check constraint to limit allowed enum values
- Never manually set `created_at` or `updated_at` unless migrating historical data
- Always include `t.timestamps null: false` in `create_table`
- Avoid `change_column` — it is not reversible; use `up/down` blocks instead

## References and Indexing

- Always add `foreign_key: true, index: true` with `add_reference`
- Always index foreign keys and frequently queried columns
- Use compound indexes for multi-column queries: `add_index :orders, [:user_id, :status]`

## Production Safety (Zero-Downtime)

- Add columns with safe defaults for existing data
- Add indexes concurrently on large tables: `algorithm: :concurrently` with `disable_ddl_transaction!`
- Separate data migrations from schema changes into distinct migration files
- Remove columns only AFTER deploying code that no longer references them
- Use `safety_assured` block when explicitly bypassing strong_migrations checks

## Data Migrations

- Use `find_each(batch_size: 1000)` for large datasets
- Use `update_columns` to skip callbacks and validations during backfills
- Always provide a reversible `down` block or document why rollback is unsafe

## Running Migrations

- `db:migrate` on a fresh DB (Rails 8.0+) loads `schema.rb` first, then runs pending migrations — fast, deterministic
- Use `db:migrate:reset` for the old behavior (drop, create, run all migrations from scratch)
- Composite primary keys: pass `primary_key: %i[a b]` to `create_table` (see `references/composite-keys.md`)

## Helpers

- Use helper methods inside long migrations to break logic apart
- Place shared helpers under `lib/tasks/migration_helpers.rb` if reused across versions

## Examples

## Table Creation with Conventions

```ruby
# db/migrate/20230701123456_create_posts.rb
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.string :status, null: false, default: "draft"
      t.references :user, null: false, foreign_key: true, index: true
      t.timestamps null: false
    end
  end
end
```

## Enum Column with Check Constraint

```ruby
add_check_constraint :posts, "status IN ('draft', 'published')", name: "posts_status_check"
```

## Irreversible Column Change (up/down)

```ruby
class FixColumnType < ActiveRecord::Migration[8.1]
  def up
    change_column :users, :admin, :boolean, default: false
  end

  def down
    change_column :users, :admin, :string
  end
end
```

## Foreign Keys and Indexing

```ruby
add_reference :comments, :post, null: false, foreign_key: true
add_index :users, :email, unique: true
add_index :orders, [:user_id, :status], name: "index_orders_on_user_and_status"
```

## Adding Timestamps to Existing Table

```ruby
add_timestamps :profiles, null: true
```

## Safe Column Addition with Defaults

```ruby
class AddUserVerificationSystem < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :verified, :boolean, default: false, null: false
    add_column :users, :verified_at, :timestamp
    add_index :users, :verified
    add_index :users, :verified_at
  end
end
```

## Data Migration (Separate from Schema)

```ruby
class BackfillUserVerificationData < ActiveRecord::Migration[8.0]
  def up
    User.where(email_confirmed: true).find_each(batch_size: 1000) do |user|
      user.update_columns(
        verified: true,
        verified_at: user.email_confirmed_at
      )
    end
  end

  def down
    User.update_all(verified: false, verified_at: nil)
  end
end
```

## Safe Column Removal

```ruby
class SafelyRemoveOldColumn < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :users, :old_email_field }
  end
end
```

## Concurrent Index (Production Safe)

```ruby
class AddConcurrentIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :posts, :published_at, algorithm: :concurrently
  end
end
```
