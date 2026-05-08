---
name: rails-antipattern-god-helper-module
description: Use when `ApplicationHelper` (or a single helper module) becomes a sprawling dumping ground of unrelated formatting, business, and query methods.
---

# Antipattern: God Helper Module

## The smell
- `ApplicationHelper` with dozens of unrelated methods
- Helpers that perform queries (`fetch_recent_posts`, `current_admin_count`)
- Business calculations in helpers (`calculate_tax(order)`)
- Predicates about the current user as global helpers
- Method names colliding or shadowing model methods

## Why it hurts
- Pollutes the global view namespace
- Mixes formatting (legitimate helper work) with queries and domain logic
- Hard to tell which view uses which helper — refactoring is risky
- New devs add to it because there's no obvious better home

## The fix
- **Split by topic**: `MoneyHelper`, `AvatarHelper`, `NavigationHelper` (auto-included by Rails)
- **Move queries to models or controllers**, not helpers
- **Move business calculations to models or POROs** (`order.tax`, not `calculate_tax(order)`)
- Keep helpers focused on **presentation**: HTML structure, formatting, escaping, i18n wrappers

## When it's actually fine
A small, cohesive `ApplicationHelper` with truly cross-cutting formatters (one or two methods) is fine. The smell is *unrelated* responsibilities and *non-presentation* logic.

## See also
- [rails-helpers](../../rails/rails-helpers/SKILL.md)
- [rails-views](../../rails/rails-views/SKILL.md)
- [php-itis-views](../rails-antipattern-php-itis-views/SKILL.md)

See `references/examples.md` for code samples.
