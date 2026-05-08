# Rails Jobs — Code Examples

## Basic Queued Job

```ruby
# app/jobs/daily_cleanup_job.rb
class DailyCleanupJob < ApplicationJob
  queue_as :low

  def perform
    CleanupService.new.call
  end
end
```

## Retry on Transient Failure

```ruby
# app/jobs/import_job.rb
class ImportJob < ApplicationJob
  retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 3

  def perform(url)
    RemoteImporter.new(url).fetch_and_store!
  end
end
```

## Discard on Validation Error

```ruby
# app/jobs/notification_job.rb
class NotificationJob < ApplicationJob
  discard_on ActiveRecord::RecordInvalid

  def perform(user_id)
    user = User.find(user_id)
    NotificationService.new(user).send_alert!
  end
end
```

## Combined Retry and Discard

```ruby
class DataImportJob < ApplicationJob
  retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 5
  discard_on ActiveRecord::RecordInvalid

  def perform(record_id)
    # fetch and process record
  end
end
```

## Mailer Delivery (prefer deliver_later)

```ruby
# GOOD
UserMailer.with(user:).welcome_email.deliver_later

# AVOID in production
UserMailer.with(user:).welcome_email.deliver_now
```
