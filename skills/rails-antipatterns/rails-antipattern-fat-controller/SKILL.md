---
name: rails-antipattern-fat-controller
description: Use when a controller action contains business logic, multi-step orchestration, or branching beyond loading/saving a resource. From *Rails Antipatterns*.
---

# Antipattern: Fat Controller

## The smell
- Action method longer than ~10 lines
- Branching on business rules inside the controller
- External API calls (Stripe, etc.) in controller code
- Multi-step orchestration: persist + email + enqueue + redirect, all inline
- Domain logic invisible from outside the HTTP path (jobs, console, API can't reuse it)

## Why it hurts
- Untestable without a full request cycle
- Logic can't be reused from a job, console, or different endpoint
- Mixes HTTP concerns (params, redirects, status codes) with domain logic
- Tends to grow indefinitely

## The fix
- **Thin controllers, fat models.** Controller responsibilities: load, authorize, dispatch, render
- Move logic onto the model as a verb (`order.place!`)
- If the verb is too big to live on the model, introduce a **new resource** (e.g. `OrderPayment`) and let the controller create *that*
- Use exceptions or result objects for failure paths

## When it's actually fine
A two-line action that loads, updates, and redirects is fine. `update_params`-style brevity is the goal.

## See also
- [rails-controllers](../../rails/rails-controllers/SKILL.md)
- [non-restful-actions](../rails-antipattern-non-restful-actions/SKILL.md)
- [anemic-domain-model](../rails-antipattern-anemic-domain-model/SKILL.md)

See `references/examples.md` for code samples.
