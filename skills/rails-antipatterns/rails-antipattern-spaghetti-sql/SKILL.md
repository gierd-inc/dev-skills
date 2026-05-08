---
name: rails-antipattern-spaghetti-sql
description: Use when raw `where(...)` clauses, `find_by_sql`, or query fragments are scattered across controllers, views, and jobs instead of being encapsulated as model scopes. From *Rails Antipatterns*.
---

# Antipattern: Spaghetti SQL

## The smell
- The same business concept ("published, recent posts") expressed slightly differently across many call sites
- `where("...")` strings in controllers and views
- `find_by_sql` and raw `connection.execute` outside of migrations

## Why it hurts
- A schema or business-rule change requires hunting every call site
- Easy to drift (one place forgets `featured`, another forgets a tenancy filter)
- SQL fragments bypass scopes, joins, and security/tenancy filters
- Test setup mirrors the SQL instead of the intent

## The fix
- Push every query into a **named scope or class method** on the model
- Name scopes for the business term, not SQL: `published`, `featured`, `recent`, `reverse_chronologically`
- For complex queries that don't compose, use a **query object PORO** (`PostsForFeed`)
- Call sites read like sentences: `Post.published.featured.recent.limit(10)`

## When it's actually fine
One-off admin scripts and rake tasks can use ad-hoc queries. The smell is *duplication* and *leakage into request handlers*.

## See also
- [rails-models](../../rails/rails-models/SKILL.md)
- [n-plus-one-in-views](../rails-antipattern-n-plus-one-in-views/SKILL.md)
- [rails-performance-and-caching](../../rails/rails-performance-and-caching/SKILL.md)

See `references/examples.md` for code samples.
