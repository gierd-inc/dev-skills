---
name: rails-composite-keys
description: use when working with composite primary keys in Active Record models and migrations
---

# Rails Composite Keys

## When to Use

- Use composite primary keys when uniqueness must span multiple columns
- Avoid them unless your data model or legacy database demands it

## Migrations

- Use `primary_key: %i[key1 key2]` when creating the table
- Do not use `t.primary_key :id` — Rails will create a single-column ID instead
- Omit `id: false` when using the `primary_key:` option directly on `create_table`

## Model Declarations

- Use the `composite_primary_key` gem
- Declare with `self.primary_keys = :user_id, :group_id` (not `primary_key=`)

## Associations

- Associations work normally; foreign keys must match the composite declaration
- Use `foreign_key: [:user_id, :group_id]` explicitly when needed
- Avoid polymorphic associations with composite keys

## Querying

- Use arrays in `find`: `Membership.find([user_id, group_id])`
- Use `where(user_id: 1, group_id: 2)` for scoped queries
- Composite keys don't support `find_by(id: ...)` unless `id` is virtualized

## Warnings

- `url_for` and `form_with` helpers may need custom routing
- Eager loading may not optimize correctly
- Test thoroughly with system and integration tests

See `references/examples.md` for code samples.
