# Rails Routes — Code Samples

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
