---
name: rails-migrations
description: use when writing Rails Active Record migrations, schema changes, indexes
---

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
- Composite primary keys: pass `primary_key: %i[a b]` to `create_table` (see `rails-composite-keys`)

## Helpers

- Use helper methods inside long migrations to break logic apart
- Place shared helpers under `lib/tasks/migration_helpers.rb` if reused across versions

See `references/examples.md` for code samples.
