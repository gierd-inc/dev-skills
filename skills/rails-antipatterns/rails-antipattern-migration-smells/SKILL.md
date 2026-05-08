---
name: rails-antipattern-migration-smells
description: Use when reviewing migrations that are irreversible, mix data backfills with schema changes, reference application models, or skip indexes on foreign keys. From *Rails Antipatterns*.
---

# Antipattern: Migration Smells

## The smells
- **Referencing app models** (`User.find_each ...`) — the model schema today is not the schema at migration time
- **Irreversible** `change` blocks doing `execute "UPDATE ..."` or destructive transforms
- **Schema + data in the same migration** — long `UPDATE`s during a deploy lock tables
- **Missing indexes on foreign keys** — joins get slower as data grows
- **No `null: false` / default** on `add_column` for required fields, leading to a follow-up "fix" migration

## Why it hurts
- Fresh-environment setup (CI, new dev machine) becomes fragile as the model evolves
- Production deploys lock tables for minutes
- Rollbacks are impossible
- Joins on un-indexed FKs slow down at scale

## The fix
- For data manipulation, use **raw SQL** or a **scoped anonymous class** — never the live model
- Use **`reversible`** or define explicit `up` / `down`
- **Split data backfills** into a separate migration (or a one-off rake task / job) deployed *after* the schema migration
- `add_reference :foo, :bar` defaults to `index: true` in Rails 5+ — verify in `schema.rb`
- Use the **strong_migrations** gem in CI to catch these mechanically

## When it's actually fine
Tiny config tables (enums, lookup rows) can mix schema + data inline. The smell is *unbounded* loops over user data inside a migration.

## See also
- [rails-migrations](../../rails/rails-migrations/SKILL.md)
- [rails-deployment](../../rails/rails-deployment/SKILL.md)

See `references/examples.md` for code samples.
