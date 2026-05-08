---
name: rails-mailers
description: use when writing Action Mailer classes, mail views, deliveries
---

# Rails Mailers

## Mailer Setup

- Define mailers in `app/mailers/`, inheriting from `ApplicationMailer`
- Always set a default sender with a human-readable format: `"MyApp Support <support@myapp.com>"`
- Always specify a `layout "mailer"` in `ApplicationMailer`
- Always use `params[:user]` (not method arguments) for passing data into mailers

## Mailer Concerns

- Place reusable logic (shared headers, tracking, helpers) in `app/mailers/concerns/`
- Use `ActiveSupport::Concern` with `before_action` hooks for cross-cutting concerns
- Include concerns explicitly in each mailer that needs them

## Previews

- Create previews under `test/mailers/previews/` with one-to-one mapping to mailer classes
- Keep preview data realistic and minimal; use fixture or test records
- Inherit from `ActionMailer::Preview`

## Delivery

- Use `deliver_later` in controllers and jobs; never `deliver_now` in production
- Always configure Action Mailer delivery method per environment

See `references/examples.md` for code samples.
