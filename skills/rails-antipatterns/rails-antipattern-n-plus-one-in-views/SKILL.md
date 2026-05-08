---
name: rails-antipattern-n-plus-one-in-views
description: Use when iterating over a collection in a view triggers a query per row — the classic N+1. Detected by Bullet, by log inspection, or by review.
---

# Antipattern: N+1 Queries (especially in views)

## The smell
- Iterating a collection that calls `.author`, `.comments.count`, or other associations per row
- 50+ "SELECT ... WHERE id = ?" queries in dev log for one page render
- Bullet gem warnings
- `.count` inside a loop (where `counter_cache` or aggregation would do)

## Why it hurts
- Latency scales linearly with rows
- DB connection pressure
- Slow in dev, catastrophic in prod
- Often invisible until production data shape changes

## The fix
- **Eager-load** in the controller or scope: `Post.includes(:author).recent`
- Define a `preloaded` scope that bundles the standard eager-loads for that model — call it everywhere the view is rendered (Gierd convention from `rails-models`)
- For counts, use **`counter_cache`** or `LEFT JOIN ... GROUP BY` aggregation rather than `.count` in a loop
- Verify with **Bullet** in dev or `assert_queries(N)` in tests

## When it's actually fine
Small fixed-cap lists (e.g. menu of 5 categories) where the extra queries are immaterial. Even then, `includes` is cheap insurance.

## See also
- [rails-performance-and-caching](../../rails/rails-performance-and-caching/SKILL.md)
- [rails-models](../../rails/rails-models/SKILL.md)
- [spaghetti-sql](../rails-antipattern-spaghetti-sql/SKILL.md)

See `references/examples.md` for code samples.
