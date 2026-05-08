# Rails Migrations — Code Examples

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
