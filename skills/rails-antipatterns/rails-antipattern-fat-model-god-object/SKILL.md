---
name: rails-antipattern-fat-model-god-object
description: Use when reviewing or refactoring an Active Record model that has grown past ~300 lines, mixes multiple responsibilities, or accumulates unrelated concerns (billing + notifications + search + auth all on `User`).
---

# Antipattern: Fat Model / God Object

## The smell
- One model owning many unrelated responsibilities (auth + billing + search + notifications + exports)
- Hundreds-to-thousands of lines, constants and scopes sprawling
- Every PR touches it; merge conflicts cluster on it

## Why it hurts
- Cognitive load — readers can't tell what the model *is*
- Tests slow because every test loads every concern's deps
- Encourages "just add it to User" forever

## The fix (in order of preference)
1. **Concerns** in `app/models/concerns/` for behavior that genuinely belongs to the model but is logically grouped (`User::Authenticatable`, `User::Billable`)
2. **Value objects / POROs** for cohesive logic operating on data (`PasswordStrength`, `SubscriptionStatus`)
3. **A new Active Record model** when the "concern" is actually a missing entity (`AccountClosure`)
4. **Background jobs** for side effects

Avoid `app/services/UserService` as the dumping ground — see [service-object-soup](../rails-antipattern-service-object-soup/SKILL.md).

## When it's actually fine
A long model that's genuinely one cohesive concept (e.g. `Invoice` with line-item math, totals, state) is fine. Length alone isn't the smell — *unrelated* responsibilities are.

## See also
- [rails-models](../../rails/rails-models/SKILL.md)
- [anemic-domain-model](../rails-antipattern-anemic-domain-model/SKILL.md)
- [service-object-soup](../rails-antipattern-service-object-soup/SKILL.md)

See `references/examples.md` for code samples.
