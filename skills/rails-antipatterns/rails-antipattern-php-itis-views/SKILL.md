---
name: rails-antipattern-php-itis-views
description: Use when ERB templates contain conditionals, loops with business rules, formatting logic, or direct queries — turning views into procedural scripts. From *Rails Antipatterns*.
---

# Antipattern: PHP-itis (logic in views)

## The smell
- Multi-clause conditionals in ERB referencing model internals
- Loops that accumulate totals, filter, or compute in the template
- `sprintf` / `Date.today` / `BigDecimal` math in views
- Same logic copy-pasted across templates
- Direct queries from views (`<% Post.published.each ... %>`)

## Why it hurts
- Untestable in isolation
- Designers can't safely edit
- Triggers N+1 queries
- Encourages duplication across templates

## The fix
- Move predicates and queries to the **model**: `@user.owes_for_premium_trial?`
- Move formatting to **helpers**: `humanized_money(...)`, `time_ago_in_words`
- Move repeated structure to **partials**
- Templates should read like sentences, not scripts

## When it's actually fine
Trivial conditionals (`<% if @posts.any? %>`) and simple iteration are fine — the smell is *business rules* in markup.

## See also
- [rails-views](../../rails/rails-views/SKILL.md)
- [rails-helpers](../../rails/rails-helpers/SKILL.md)
- [voyeuristic-model](../rails-antipattern-voyeuristic-model/SKILL.md)

See `references/examples.md` for code samples.
