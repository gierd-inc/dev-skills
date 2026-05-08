# Rails Deployment Examples

## deploy.yml (Full Example)

```yaml
service: myapp
image: myapp

servers:
  web:
    - 192.168.1.1
    - 192.168.1.2
  job:
    hosts:
      - 192.168.1.3
    cmd: bin/jobs

proxy:
  ssl: true
  host: myapp.com

registry:
  server: ghcr.io
  username: myusername
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    RAILS_SERVE_STATIC_FILES: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL

volumes:
  - "/app/storage:/rails/storage"

healthcheck:
  path: /up
  port: 3000
  max_attempts: 10
  interval: 5s

asset_path: /rails/public/assets
boot:
  limit: 10
```

## .kamal/secrets

```bash
# .kamal/secrets — interpolated at deploy time, never committed
KAMAL_REGISTRY_PASSWORD=$(rails credentials:fetch kamal.registry_password)
RAILS_MASTER_KEY=$(cat config/master.key)
```

## Staging deploy.yml

```yaml
# config/deploy.staging.yml
service: myapp-staging
image: myapp

servers:
  web:
    hosts:
      - 192.168.1.10

env:
  clear:
    RAILS_ENV: staging
    RAILS_SERVE_STATIC_FILES: true
  secret:
    - RAILS_MASTER_KEY
    - STAGING_DATABASE_URL
```

## Production Dockerfile

Closely mirrors the Rails 8 generated Dockerfile: slim base, jemalloc, YJIT, Thruster fronting Puma.

```dockerfile
ARG RUBY_VERSION=3.3.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    LD_PRELOAD=libjemalloc.so.2 \
    MALLOC_CONF=dirty_decay_ms:1000,narenas:2,background_thread:true \
    RUBY_YJIT_ENABLE=1

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Thruster fronts Puma: serves compressed assets, X-Sendfile, caching.
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
```

## config/environments/production.rb

```ruby
Rails.application.configure do
  config.eager_load = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=31536000' }

  config.assets.compile = false
  config.assets.compress = true
  config.assets.digest = true

  config.force_ssl = true
  config.ssl_options = {
    hsts: { expires: 1.year, subdomains: true, preload: true },
    secure_cookies: true
  }

  config.log_level = :info
  config.colorize_logging = false
  config.log_tags = [:request_id, :remote_ip]

  config.consider_all_requests_local = false
  config.active_record.dump_schema_after_migration = false
  config.active_record.query_cache_enabled = true
end
```

## Health Check Controller

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :require_authentication

  def show
    if healthy?
      render json: { status: 'ok', timestamp: Time.current.iso8601 }
    else
      render json: { status: 'error', timestamp: Time.current.iso8601 },
             status: :service_unavailable
    end
  end

  private

  def healthy?
    ActiveRecord::Base.connection.execute('SELECT 1')
    Rails.cache.write('health_check', 'ok')
    Rails.cache.read('health_check') == 'ok'
  rescue
    false
  end
end
```

## database.yml (Production)

```yaml
production:
  primary:
    <<: *default
    url: <%= ENV['DATABASE_URL'] %>
    pool: <%= ENV.fetch('DB_POOL', 25) %>
    checkout_timeout: <%= ENV.fetch('DB_CHECKOUT_TIMEOUT', 5) %>
    variables:
      statement_timeout: 60000
      lock_timeout: 10000
    prepared_statements: true
  cache:
    <<: *default
    url: <%= ENV['CACHE_DATABASE_URL'] %>
    migrations_paths: db/cache_migrate
```

## SSL and Security Headers

```ruby
# config/environments/production.rb
config.force_ssl = true
config.ssl_options = {
  hsts: { expires: 1.year, subdomains: true, preload: true },
  secure_cookies: true
}

# Optional: custom security headers middleware
class SecurityHeadersMiddleware
  def initialize(app) = @app = app

  def call(env)
    status, headers, response = @app.call(env)
    headers['X-Frame-Options'] = 'DENY'
    headers['X-Content-Type-Options'] = 'nosniff'
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    [status, headers, response]
  end
end

config.middleware.use SecurityHeadersMiddleware
```
