# Rails Routes

## General Conventions
- Always prefer `resources` over manual route declarations
- Use `only:` or `except:` to limit unnecessary routes
- Use `root to:` for root-level route definition
- Organize routes into blocks with comments for clarity
- Do not pass an array of paths to a single route (e.g. `get ["foo", "bar"], to: ...`) — deprecated in Rails 8.0; declare each path separately

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

## Examples

## Basic Resource Routing

```ruby
resources :articles
```

## Root and Auth Routes

```ruby
# Public site
root to: "home#index"

# Auth
get "/login" => "sessions#new"
post "/login" => "sessions#create"
delete "/logout" => "sessions#destroy"
```

## Nested + Shallow Routing

```ruby
resources :users do
  resources :posts, shallow: true
end

resources :projects do
  resources :tasks, shallow: true
end
```

## Custom Member + Collection Actions

```ruby
resources :posts do
  member do
    post :publish
  end
  collection do
    get :archived
  end
end

resources :invoices do
  member do
    post :approve
  end
  collection do
    get :archived
  end
end
```

## Turbo Stream Format Defaults

```ruby
resources :comments, only: [:create, :destroy], defaults: { format: :turbo_stream }
```

## Authentication Route Scoping

```ruby
scope :account do
  get "signup", to: "users#new", as: :signup
  post "signup", to: "users#create"
end
```

## Route Constraints

```ruby
constraints format: :json do
  namespace :api do
    resources :events
  end
end

constraints subdomain: "admin" do
  namespace :admin do
    resources :users
  end
end
```

## Mailbox Route

```ruby
receive "support@example.com" => "support_mailbox"
receive "feedback@example.com" => "feedback_mailbox"
```

## Default URL Options

```ruby
# config/initializers/default_url_options.rb
Rails.application.routes.default_url_options[:host] = ENV.fetch("APP_HOST", "localhost")
```
