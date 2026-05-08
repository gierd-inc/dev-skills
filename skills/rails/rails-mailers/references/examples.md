# Rails Mailers — Code Examples

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
