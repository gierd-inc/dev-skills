---
name: rails-autoloading
description: use when dealing with Zeitwerk autoloading, constant resolution, file naming, eager loading, or autoload errors
---

# Rails Autoloading (Zeitwerk)

## File-to-Constant Naming

- `snake_case` file name maps to `CamelCase` constant — strictly enforced
- `app/models/blog_post.rb` -> `BlogPost`
- `app/controllers/admin/users_controller.rb` -> `Admin::UsersController`
- `app/services/payment_gateway/stripe_service.rb` -> `PaymentGateway::StripeService`
- Verify setup with `bin/rails zeitwerk:check`

## Directory Structure and Namespaces

- Directories automatically create namespace modules
- `app/models/payment/credit_card.rb` -> `Payment::CreditCard`
- `app/controllers/admin/users_controller.rb` -> `Admin::UsersController`
- Avoid naming conflicts: `Admin::User` vs `::User` — use distinct names like `Admin::UserAccount`

## Custom Autoload Paths

```ruby
# config/application.rb
# Preferred (Rails 7.1+, default in new apps): adds `lib/` to autoload + eager-load paths
config.autoload_lib(ignore: %w(assets tasks generators))
# Once-only variant for code that should not reload:
# config.autoload_lib_once(ignore: %w(assets tasks))
# NOTE: autoload_lib is not available in engines.

# Manual paths for other directories:
config.autoload_paths << Rails.root.join('app', 'forms')
```

## Custom Inflections for Acronyms

Register acronyms so Zeitwerk resolves them correctly:

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
  inflect.acronym 'URL'
  inflect.acronym 'PDF'
end

# config/initializers/zeitwerk.rb
Rails.autoloaders.main.inflector.inflect(
  "html_parser" => "HTMLParser",
  "json_web_token" => "JSONWebToken",
  "pdf_generator" => "PDFGenerator"
)
```

## Reloading-Safe Patterns

- Use `config.to_prepare` for initialization code that must re-run after reloads
- Avoid top-level constants assigned at load time (e.g. `GATEWAYS = Gateway.all` is unsafe)
- Use class methods or lazy configuration instead

```ruby
config.to_prepare do
  ApplicationEvents.setup_listeners
end
```

## Production Eager Loading

- `config.eager_load = true` in production (default)
- STI subclasses must be eager loaded — add them to `eager_load_paths` or load explicitly
- Use `config.active_record.store_full_sti_class = true` for namespaced STI

## Debugging Autoload Errors

- `bin/rails zeitwerk:check` — validates all files load correctly
- Enable logging: `Rails.autoloaders.log!` in development
- `NameError` on constant -> check file path matches expected constant
- Circular dependency -> move to instance method or use string class reference

## Common Mistakes

- File named `payment_gateway_service.rb` but class is `PaymentGateway::Service` — mismatch
- Assigning global variables at load time (`CACHE = Model.all`) — breaks reloading
- Missing namespace module file (e.g. `app/models/payment.rb` for `Payment::*`)

See `references/examples.md` for naming patterns and directory structures.
