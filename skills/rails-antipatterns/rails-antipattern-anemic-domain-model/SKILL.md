---
name: rails-antipattern-anemic-domain-model
description: Use when models are reduced to bags of attributes with all behavior living in `app/services/`, `app/use_cases/`, or controllers. Fowler's anemic domain model, applied to Rails.
---

# Antipattern: Anemic Domain Model

## The smell
- Models containing only validations, associations, and scopes — no verbs
- `app/services/` full of `*Service` / `*UseCase` classes that orchestrate model attribute changes
- "Where does X happen?" → "search `services/`"
- Tests stub the services rather than exercising the models

## Why it hurts
- Behavior is hard to discover — readers have to know the service exists
- Conditional dispatch creeps into services because models can't answer questions about themselves
- Every new verb is a new class with `#call`, plus a spec, plus wiring
- Encourages procedural style; weakens domain reasoning

## The fix
- **Put behavior on the model.** A `Post` should know how to publish itself
- Extract a **concern** if the behavior has its own cluster of methods
- Extract a **PORO named as a noun** (`PostPublication`) — but the entry point stays on the model
- This is core to the 37signals/DHH style: `post.publish`, not `PublishPostService.call(post)`

## When it's actually fine
A class is genuinely warranted when an operation spans multiple aggregates and doesn't naturally belong to any one model. Even then, name it as a **noun** (`PaymentReconciliation`), not `*Service`.

## See also
- [rails-models](../../rails/rails-models/SKILL.md)
- [service-object-soup](../rails-antipattern-service-object-soup/SKILL.md)
- [fat-model-god-object](../rails-antipattern-fat-model-god-object/SKILL.md)

See `references/examples.md` for code samples.
