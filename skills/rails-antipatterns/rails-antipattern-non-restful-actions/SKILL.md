---
name: rails-antipattern-non-restful-actions
description: Use when controllers grow custom actions like `publish`, `archive`, `approve`, `notify_users` instead of introducing a new resource. DHH's "use REST" rule.
---

# Antipattern: Non-RESTful Actions

## The smell
- `member do; post :publish; post :archive; post :feature; end` and similar in `routes.rb`
- Controllers with 8+ public actions, most of them custom verbs
- Pairs of verbs that are obviously create/destroy: `publish`/`unpublish`, `archive`/`unarchive`, `feature`/`unfeature`
- URLs that read RPC-ish (`POST /posts/:id/publish`)

## Why it hurts
- No conventions to lean on — every action is bespoke
- Authorization, redirects, and templates duplicate
- Form objects, params, and responses don't compose
- Discoverability suffers; URL shape gives no hint about behavior

## The fix
- **Each verb is a new resource.** Canonical DHH move
- `publish`/`unpublish` → `resource :publication, only: [:create, :destroy]`
- The new resource often *is* a real record (see "State as Records" in `rails-models`); even when it isn't, the routing convention pays off
- Controllers stay short and RESTful; URLs become `POST /posts/42/publication`

## When it's actually fine
Truly idempotent, parameter-less queries that don't fit a resource (`GET /search`) are okay. But a 4th custom member action means a hidden resource — find it.

## See also
- [rails-routes](../../rails/rails-routes/SKILL.md)
- [rails-controllers](../../rails/rails-controllers/SKILL.md)
- [fat-controller](../rails-antipattern-fat-controller/SKILL.md)

See `references/examples.md` for code samples.
