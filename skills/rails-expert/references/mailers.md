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

## Examples

## Application Mailer Base

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "MyApp Support <support@myapp.com>"
  layout "mailer"
end
```

## Basic Mailer

```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def welcome
    @user = params[:user]
    mail(to: @user.email, subject: "Welcome to MyApp")
  end
end
```

## Mailer Preview

```ruby
# test/mailers/previews/user_mailer_preview.rb
class UserMailerPreview < ActionMailer::Preview
  def welcome
    UserMailer.with(user: User.first).welcome
  end
end
```

## Mailer Concern

```ruby
# app/mailers/concerns/trackable_mailer.rb
module TrackableMailer
  extend ActiveSupport::Concern

  included do
    before_action :inject_tracking
  end

  def inject_tracking
    # Custom tracking logic
  end
end
```

## Mailer Using a Concern

```ruby
# app/mailers/notification_mailer.rb
class NotificationMailer < ApplicationMailer
  include TrackableMailer

  def mention
    @user = params[:user]
    mail(to: @user.email, subject: "You were mentioned!")
  end
end
```
