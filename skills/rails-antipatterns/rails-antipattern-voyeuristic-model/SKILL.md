---
name: rails-antipattern-voyeuristic-model
description: Use when reviewing code that reaches across multiple objects to get at data — train wrecks like `order.customer.address.city` — violating the Law of Demeter. From *Rails Antipatterns* (Pytel & Saleh).
---

# Antipattern: Voyeuristic Model

## The smell
- Callers traversing 3+ associations to read data: `order.customer.address.city`
- Same chain repeated across views, controllers, mailers
- `&.` peppered through chains to dodge nil

## Why it hurts
- A nil anywhere raises `NoMethodError on nil`
- Renaming or restructuring an association breaks every call site
- Views and controllers grow knowledge of model internals
- Hard to mock or stub for tests

## The fix
- Use `delegate` for thin pass-throughs (`delegate :city, to: :customer`)
- Add a method that expresses the **intent**, not the path (`invoice.billed_to`)
- Tell, don't ask: push the question down to the object that owns the data
- Ensure non-optional `belongs_to` (Rails default) so `&.` isn't needed

## When it's actually fine
A two-step reach (`post.author.name`) inside a model method is usually fine. The smell is depth-3+ chains in views/controllers, or repeating the same chain in many places.

## See also
- [rails-models](../../rails/rails-models/SKILL.md)
- [php-itis-views](../rails-antipattern-php-itis-views/SKILL.md)

See `references/examples.md` for code samples.
