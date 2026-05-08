---
name: rails-controllers
description: Use when working with Rails controllers, RESTful actions, strong params, before_actions, respond_to, Turbo streams, or controller concerns.
---

# Rails Controllers

## Structure
- Only RESTful public actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- If a controller needs custom public methods, extract them to a new controller scoped to that feature
- Use `respond_to` in `create`, `update`, and `destroy` — not in `index` unless multi-format is needed

## REST Mapping (resources, not verbs)
- For non-CRUD actions, create a new resource rather than a custom verb on the existing controller
  - `POST /cards/:id/close` → `Cards::ClosuresController#create` (`POST /cards/:id/closure`)
  - `DELETE /cards/:id/close` → `Cards::ClosuresController#destroy`
  - `POST /cards/:id/archive` → `Cards::ArchivalsController#create`
- The new resource is often a real record (see "State as Records" in `rails-models`), so the controller stays plainly RESTful

## Configuration Order
Always declare configuration in this order:
1. Authentication/authorization declarations
2. Rate limiting
3. Before actions

## Strong Parameters
- Use `params.expect(model_name: [...])` — this is the modern, more secure standard
- Never use `params.require(...).permit(...)`
- Always define a private `model_params` method for create/update actions

## Authentication & Authorization
- Use `allow_unauthenticated_access only: %i[new create]` from Rails built-in authentication
- Use `allow_bot_access only: %i[show]` (Rails 8 feature)
- Use `Current` object for user context
- Use descriptive method names for authorization checks
- Return appropriate HTTP status codes (`head :forbidden`, etc.)

## Rate Limiting
- Use declarative rate limiting syntax
- Always provide a custom rejection handler

## Turbo Stream Responses
- Use `respond_to` with `format.turbo_stream` in create/update/destroy
- Prefer Turbo stream updates over redirects when possible
- Use `turbo_stream.replace`, `turbo_stream.prepend`, etc.

## Error Handling
- Use controller-level `rescue_from` handlers in `ApplicationController`
- Provide user-friendly error responses
- Use semantic HTTP status codes: `:not_found`, `:forbidden`, `:unprocessable_entity`

## Before Actions
- Scope with `only:` or `except:` — never blanket before_actions
- Keep before_actions focused: set records, check auth
- Use `set_model` naming convention for record-finders

## Controller Concerns
- Shared controller logic (filters, auth, lookups) lives in `app/controllers/concerns/`
- Use `included do` block to register `before_action` hooks
- Include concerns explicitly in controllers

## Response Patterns
- Use `redirect_to @post, status: :see_other` after successful create/update
- Use `render :new, status: :unprocessable_entity` on failure
- Use semantic HTTP status codes consistently across similar actions

See `references/examples.md` for code samples.
