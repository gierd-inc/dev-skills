---
name: rails-antipattern-callback-hell
description: Use when a model has a tangle of `before_*` / `after_*` callbacks that fire side effects (emails, jobs, external API calls, audit rows) on every save, making behavior unpredictable and tests slow.
---

# Antipattern: Callback Hell

## The smell
- Multiple `after_create` / `after_save` / `after_commit` callbacks doing side effects (charges, emails, jobs, external APIs)
- `update_columns` used as a workaround to skip them
- Tests must stub or skip callbacks to keep the suite fast
- "Save without notifying" requires hacks

## Why it hurts
- Implicit side effects — call sites can't see what happens
- Callback ordering bugs are silent and rare-to-reproduce
- Re-saving for unrelated reasons re-fires effects
- Hard to compose alternative flows (admin imports, backfills)

## The fix
- **Make side effects explicit at the call site.** Replace lifecycle callbacks with named methods controllers/jobs invoke
- Push async work to **jobs** triggered explicitly, not from `after_commit`
- Reserve callbacks for **invariants tightly coupled to persistence**: `before_validation` normalization, derived columns, `dependent: :destroy` — things that don't reach outside the row

## When it's actually fine
- `before_validation` for normalization (email downcase, slug generation)
- `after_commit` for *idempotent* bookkeeping that genuinely must follow every persistence
- `dependent: :destroy`

## See also
- [rails-models](../../rails/rails-models/SKILL.md)
- [rails-jobs](../../rails/rails-jobs/SKILL.md)
- [fat-model-god-object](../rails-antipattern-fat-model-god-object/SKILL.md)

See `references/examples.md` for code samples.
