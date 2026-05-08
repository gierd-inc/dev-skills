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

## Bulk Enqueue

```ruby
jobs = User.find_each.map { |u| NotificationJob.new(u.id) }
ActiveJob.perform_all_later(jobs)
```

## Resumable Long-Running Job (Rails 8.1+)

```ruby
class BackfillJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(model)
    step :reset_counters
    step :backfill_data do |step|
      model.find_each(start: step.cursor) do |record|
        record.update!(counter: record.children.count)
        step.advance! from: record.id
      end
    end
  end

  private

  def reset_counters
    # ...
  end
end
```

## Transactional Enqueue (no after_commit wrapper needed)

```ruby
ApplicationRecord.transaction do
  order.update!(state: :paid)
  # Enqueued only if the transaction commits — automatic since Rails 7.2
  ReceiptJob.perform_later(order.id)
end
```

## Mailer Delivery (prefer deliver_later)

```ruby
# GOOD
UserMailer.with(user:).welcome_email.deliver_later

# AVOID in production
UserMailer.with(user:).welcome_email.deliver_now
```
