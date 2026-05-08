# Rails Deployment Examples

## deploy.yml (Full Example)

```yaml
service: myapp
image: myapp

servers:
  web:
    hosts:
      - 192.168.1.1
      - 192.168.1.2
    labels:
      traefik.http.routers.myapp.rule: Host(`myapp.com`)
      traefik.http.routers.myapp.tls: true
      traefik.http.routers.myapp.tls.certresolver: letsencrypt
  job:
    hosts:
      - 192.168.1.3
    cmd: bundle exec sidekiq

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
    - REDIS_URL

volumes:
  - "/app/storage:/rails/storage"

healthcheck:
  path: /health
  port: 3000
  max_attempts: 10
  interval: 5s

asset_path: /rails/public/assets
boot:
  limit: 10
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

```dockerfile
FROM ruby:3.2-alpine AS base

RUN apk add --no-cache build-base postgresql-dev git nodejs npm

WORKDIR /rails

FROM base AS gems
COPY Gemfile Gemfile.lock ./
RUN bundle config --global frozen 1 && \
    bundle install --without development test

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM base AS app
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --from=gems /rails/node_modules /rails/node_modules
COPY . .

RUN SECRET_KEY_BASE=DUMMY bundle exec rails assets:precompile

RUN addgroup -g 1000 -S rails && adduser -u 1000 -S rails -G rails
RUN chown -R rails:rails /rails
USER rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
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
