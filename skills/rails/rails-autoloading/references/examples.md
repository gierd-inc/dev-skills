# Rails Autoloading Examples

## File-to-Constant Mapping

```
app/
  models/
    user.rb                          # User
    blog_post.rb                     # BlogPost
    concerns/
      authenticatable.rb             # Authenticatable
    payment/
      credit_card.rb                 # Payment::CreditCard
      subscription.rb                # Payment::Subscription
  services/
    notification_service.rb          # NotificationService
    payment_gateway/
      stripe_service.rb              # PaymentGateway::StripeService
      paypal_service.rb              # PaymentGateway::PaypalService
  controllers/
    application_controller.rb        # ApplicationController
    admin/
      base_controller.rb             # Admin::BaseController
      users_controller.rb            # Admin::UsersController
```

## Custom Autoload Paths

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Rails 7.1+: include `lib/` in autoload + eager-load paths (default in new apps).
    # Not available for engines.
    config.autoload_lib(ignore: %w(assets tasks generators))

    config.autoload_paths << Rails.root.join('app', 'forms')
    config.autoload_paths << Rails.root.join('app', 'presenters')
  end
end
```

## Custom Inflections

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
  inflect.acronym 'URL'
  inflect.acronym 'HTTP'
  inflect.acronym 'JSON'
  inflect.acronym 'PDF'
  inflect.acronym 'UUID'
end

# config/initializers/zeitwerk.rb
Rails.autoloaders.main.inflector.inflect(
  "html_parser" => "HTMLParser",
  "json_web_token" => "JSONWebToken",
  "pdf_generator" => "PDFGenerator",
  "api_client" => "APIClient"
)
```

## Reloading-Safe Initialization

```ruby
# config/application.rb
Rails.application.config.to_prepare do
  ApplicationEvents.setup_listeners
  ApplicationConfiguration.setup
end

# Safe configuration class (idempotent)
class ApplicationConfiguration
  class << self
    def setup
      configure! unless configured?
    end

    def configured?
      @configured ||= false
    end

    def configure!
      @api_clients = build_api_clients
      @configured = true
    end

    private

    def build_api_clients
      { stripe: StripeClient.new(ENV['STRIPE_SECRET_KEY']) }
    end
  end
end
```

## STI and Eager Loading

```ruby
# config/application.rb
config.active_record.store_full_sti_class = true

# Explicit STI loading for production
Rails.application.config.after_initialize do
  if Rails.application.config.eager_load
    %w[Car Truck Motorcycle].each(&:constantize)
  end
end
```

## Reloadable Module with ActiveSupport::Concern

```ruby
# app/models/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    has_secure_password
    validates :email, presence: true, uniqueness: true
  end

  def authenticate(password)
    authenticate_password(password)
  end

  class_methods do
    def find_by_credentials(email, password)
      user = find_by(email: email)
      user&.authenticate(password) ? user : nil
    end
  end
end
```

## Debugging Autoloading

```ruby
# In development console or initializer
Rails.autoloaders.log!

# Check a specific constant
begin
  "PaymentGateway::StripeService".constantize
  puts "OK"
rescue NameError => e
  puts "Failed: #{e.message}"
  Rails.autoloaders.main.dirs.each { |d| puts "  search: #{d}" }
end
```

## Common Naming Mistakes

```ruby
# WRONG: file app/services/payment_gateway_service.rb
#        but class is PaymentGateway::Service
# Zeitwerk expects PaymentGatewayService

# CORRECT option 1:
# app/services/payment_gateway_service.rb -> class PaymentGatewayService

# CORRECT option 2:
# app/services/payment_gateway/service.rb -> class PaymentGateway::Service

# WRONG: Namespace conflict
module Admin
  class User < ApplicationRecord  # conflicts with ::User
  end
end

# CORRECT: Use distinct names
module Admin
  class UserAccount < ApplicationRecord
  end
end
```
