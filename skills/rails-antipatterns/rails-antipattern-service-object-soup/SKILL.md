---
name: rails-antipattern-service-object-soup
description: Use when `app/services/` is filling up with `*Service` classes that wrap one or two model calls each, displacing behavior that belongs on the model. The 37signals/DHH critique of "service object" culture.
---

# Antipattern: Service Object Soup

## The smell
- `app/services/` full of verb-named `*Service` classes (`CreateUserService`, `UpdateUserService`, `SendWelcomeEmailService`)
- Each has `def self.call(...)` or `def initialize; def call`
- Models are inert — services orchestrate every change
- Tests stub the service collaborators rather than exercising the model
- Discoverability: "where does X happen?" → "search `services/`"

## Why it hurts
- Models become anemic ([anemic-domain-model](../rails-antipattern-anemic-domain-model/SKILL.md))
- Verb-named classes don't compose — DI gymnastics needed to chain them
- Encourages procedural code in OO clothing
- DHH/Manrubia: "Vanilla Rails is plenty." Concerns + POROs + AR verbs cover most cases

## The fix (preferred order)
1. **Method on the model** — `user.charge_card(token)`, `post.publish`
2. **Concern** for grouped behavior — `User::Billable`, `Post::Publishable`
3. **PORO named as a noun** (not `*Service`) — `Reconciliation`, `OnboardingFlow`, `WeeklyDigest`
4. **Active Record model** when the operation is itself an entity — `Subscription`, `OrderPayment`
5. **Job** for async side effects

## When it's actually fine
Operations spanning clearly-separated subsystems (payments, search indexing, third-party integrations) and not belonging to any one model can live in their own folder. Even then, name them as **nouns**, avoid `*Service`, and avoid class-method `.call` as the only API.

## See also
- [anemic-domain-model](../rails-antipattern-anemic-domain-model/SKILL.md)
- [rails-the-rails-way](../../rails/rails-the-rails-way/SKILL.md)
- [premature-abstraction-and-di](../rails-antipattern-premature-abstraction-and-di/SKILL.md)

See `references/examples.md` for code samples.
