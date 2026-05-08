# Rails Error Handling — Code Examples

## Validation Errors

```ruby
class Post < ApplicationRecord
  validate :title_must_be_clickworthy

  def title_must_be_clickworthy
    errors.add(:title, "must start with a number or emoji") unless title =~ /^\d|^\p{Emoji}/
  end
end
```

## Custom Error Pages

```ruby
# config/application.rb
config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }

# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  def show
    status = request.path[1..-1]
    render status.to_sym, status: status
  end
end
```

## rescue_from in ApplicationController

```ruby
rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

private

def render_not_found
  render 'errors/404', status: :not_found
end
```

## Custom Error Hierarchy

```ruby
class ApplicationError < StandardError
  attr_reader :context, :error_code

  def initialize(message, context: {}, error_code: nil)
    super(message)
    @context = context
    @error_code = error_code
  end
end

class AuthenticationError < ApplicationError
  def initialize(message = "Authentication failed", **options)
    super(message, error_code: 'AUTH_001', **options)
  end
end

class ValidationError < ApplicationError
  attr_reader :errors

  def initialize(errors, **options)
    @errors = errors
    super("Validation failed: #{errors.full_messages.join(', ')}",
          context: { validation_errors: errors.to_hash },
          error_code: 'VALID_001', **options)
  end
end

class ExternalServiceError < ApplicationError
  def initialize(service, original_error, **options)
    super("External service error: #{service}",
          context: { service: service, original_error: original_error.message },
          error_code: 'EXT_001', **options)
  end
end
```

## Rails.error in Models and Jobs

```ruby
# Model
def update_engagement_metrics
  Rails.error.handle(fallback: -> { false }) do
    update!(engagement_score: calculate_engagement_score)
  end
end

# Job with context tagging
class EmailDeliveryJob < ApplicationJob
  retry_on Net::SMTPServerBusy, wait: :exponentially_longer, attempts: 3

  def perform(user_id, template, data)
    user = User.find(user_id)
    Rails.error.handle(EmailDeliveryError.new) do |error|
      UserMailer.send(template, user, data).deliver_now
    rescue => e
      error.set_tags(user_id: user_id, template: template, job_id: job_id)
      error.set_context(queue: queue_name, retry_count: executions)
      raise e
    end
  end
end
```

## Honeybadger Configuration

```ruby
# config/initializers/honeybadger.rb
Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
  config.environment = Rails.env

  config.before_notify do |notice|
    notice.halt! if notice.error_class == "ActionController::RoutingError"
    notice.context.merge!(server: Socket.gethostname, commit: ENV['GIT_COMMIT'])
  end
end
```

## Sentry Configuration

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.before_send = lambda do |event, hint|
    if hint[:exception].is_a?(ApplicationError)
      event.fingerprint = [hint[:exception].class.name, hint[:exception].error_code]
    end
    event
  end
end
```

## Circuit Breaker

```ruby
class CircuitBreaker
  FAILURE_THRESHOLD = 5
  RECOVERY_TIMEOUT = 60.seconds

  def initialize(service_name)
    @service_name = service_name
    @failure_count = 0
    @last_failure_time = nil
    @state = :closed
  end

  def call
    if @state == :open
      if Time.current - @last_failure_time > RECOVERY_TIMEOUT
        @state = :half_open
      else
        raise CircuitBreakerOpenError, "Circuit open for #{@service_name}"
      end
    end

    result = yield
    @failure_count = 0
    @state = :closed
    result
  rescue => e
    @failure_count += 1
    @last_failure_time = Time.current
    @state = :open if @failure_count >= FAILURE_THRESHOLD
    raise e
  end
end

class ExternalApiService
  def fetch_data
    @circuit_breaker.call { HTTParty.get('https://api.example.com/data') }
  rescue CircuitBreakerOpenError
    Rails.cache.read('external_api_fallback') || { error: 'Service temporarily unavailable' }
  end
end
```

## Structured Logging with Request Context

```ruby
class ApplicationController < ActionController::Base
  around_action :log_request_context

  private

  def log_request_context
    Rails.logger.with_context(
      request_id: request.uuid,
      user_id: current_user&.id,
      ip_address: request.remote_ip
    ) { yield }
  end
end
```

## Tagged Logging

```ruby
Rails.logger.tagged("User: #{current_user.id}") { logger.info "Starting job..." }

# config/environments/production.rb
config.log_tags = [:request_id, ->(req) { "User: #{req.env['warden']&.user&.id}" }]
```

## Structured Events (Rails.event, 8.1+)

```ruby
# Emit
Rails.event.notify("order.placed", order_id: order.id, total_cents: order.total_cents)

# Ambient tags + context (e.g. in a controller around_action)
around_action do |_, block|
  Rails.event.set_context(request_id: request.uuid, user_id: current_user&.id)
  Rails.event.tagged("web") { block.call }
end

# Subscriber (any object responding to #emit)
class AnalyticsSubscriber
  def emit(event)
    Analytics.track(event.name, event.payload.merge(event.context))
  end
end

Rails.event.subscribe(AnalyticsSubscriber.new)
```

## Debug Gem Usage

```ruby
# Gemfile
gem "debug", ">= 1.0.0"

# In code
def create
  @post = Post.new(post_params)
  debugger  # interactive breakpoint
  @post.save ? redirect_to(@post) : render(:new, status: :unprocessable_entity)
end

# Conditional breakpoint
orders.each do |order|
  debugger if order.total > 1000 || order.user.vip?
  process_order(order)
end
```

## Rails Console Debugging Helpers

```ruby
# Enable SQL logging in console
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Useful console snippets
User.joins(:posts).where(posts: { published: true }).explain
Benchmark.ms { User.includes(:posts).limit(100).to_a }
user.posts.loaded?  # check if association already in memory
```

## N+1 Query Detector

```ruby
module QueryDebugger
  def self.find_n_plus_one_queries
    queries = []
    ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries << payload[:sql] unless payload[:name] =~ /SCHEMA/
    end
    yield
    queries.group_by { |sql| sql.gsub(/\d+/, 'N') }.each do |pattern, matches|
      puts "Potential N+1 (#{matches.size}x): #{pattern}" if matches.size > 5
    end
  end
end

# QueryDebugger.find_n_plus_one_queries { Post.all.map(&:author) }
```

## Health Check Controller

```ruby
class HealthController < ApplicationController
  skip_before_action :require_authentication

  def show
    results = {
      database: check_database,
      redis: check_redis
    }
    healthy = results.values.all? { |r| r[:healthy] }
    render json: results.merge(healthy: healthy),
           status: healthy ? :ok : :service_unavailable
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { healthy: true }
  rescue => e
    { healthy: false, error: e.message }
  end

  def check_redis
    Rails.cache.write('health_check', 'ok', expires_in: 1.minute)
    { healthy: Rails.cache.read('health_check') == 'ok' }
  rescue => e
    { healthy: false, error: e.message }
  end
end
```
