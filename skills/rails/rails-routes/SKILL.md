---
name: rails-routes
description: Use when working with Rails routing, resourceful routes, route constraints, namespacing, or config/routes.rb.
---

# Rails Routes

## General Conventions
- Always prefer `resources` over manual route declarations
- Use `only:` or `except:` to limit unnecessary routes
- Use `root to:` for root-level route definition
- Organize routes into blocks with comments for clarity

## RESTful Resources
- Always define RESTful routes with `resources`
- Nest resources only when the relationship is meaningful in the URL
- Use `shallow: true` for deeply nested resources to avoid long URLs

## Custom Actions
- Define member/collection routes inside the `resources` block
- `member do` for actions on a specific record (adds `:id`)
- `collection do` for actions on the collection (no `:id`)

## Turbo Stream Routes
- Use `defaults: { format: :turbo_stream }` when defining Turbo-specific resource routes
- Ensure controller actions respond to `format.turbo_stream`

## Authentication Routes
- Use `bin/rails g authentication` generator
- Scope session and registration routes logically
- Use `as:` and `path:` to keep route helpers and URLs clean

## Route Constraints
- Use constraints for custom routing logic (subdomains, formats, etc.)
- Use `constraints subdomain: "admin"` with `namespace :admin` for subdomain routing
- Use `constraints format: :json` for API namespacing

## Mailbox Routing
- Route mailboxes using `receive "support@example.com" => "support_mailbox"`

## Default URL Options
- Set `default_url_options` in an initializer, not in ApplicationController
- Always use `ENV.fetch` for host values in production

See `references/examples.md` for code samples.
