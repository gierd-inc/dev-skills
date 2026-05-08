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

See `references/examples.md` for code samples.
