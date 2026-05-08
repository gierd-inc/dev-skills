---
name: rails-deployment
description: use when configuring Kamal deployment, Dockerfile for Rails, production environment, deploy.yml
---

# Rails Deployment

## Kamal Essentials

- Use Kamal 2 for zero-downtime deployments to VPS/bare metal (default in Rails 8)
- Kamal Proxy fronts the app (replaces Traefik) — TLS via Let's Encrypt is built in
- `kamal deploy` for production, `kamal deploy -d staging` for staging
- Secrets live in `.kamal/secrets` (env interpolation, not committed)
- Pull the registry password from encrypted credentials so only `RAILS_MASTER_KEY` is needed on the deployer:
  `KAMAL_REGISTRY_PASSWORD=$(kamal secrets fetch --account myuser kamal/registry_password)`
  or `rails credentials:fetch kamal.registry_password` (Rails 8.1)
- Registry-free Kamal (2.8+) runs a local registry by default; remote still recommended at scale
- Clear env vars in `env.clear`, secret refs in `env.secret`

### deploy.yml Structure

```yaml
service: myapp
image: myapp

servers:
  web:
    - 192.168.1.1

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
```

## Dockerfile

- Use the generated multi-stage Dockerfile from `rails new` as the baseline
- Thruster sits in front of Puma (X-Sendfile, asset caching, gzip/brotli compression)
- jemalloc is preinstalled and `LD_PRELOAD`ed for lower memory fragmentation
- YJIT is on by default on Ruby 3.3+ (~15-25% latency win); leave it on
- Default Puma threads dropped from 5 → 3 (lower GVL contention) — keep that default unless benchmarks say otherwise
- Install only production gems (`--without development test`)
- Precompile assets with `SECRET_KEY_BASE_DUMMY=1`
- Run as non-root user (`rails:rails`)
- Expose port 80 (Thruster) → Puma on 3000

## Production Configuration

- `config.eager_load = true`
- `config.force_ssl = true`
- `config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?`
- Cache headers: `Cache-Control: public, max-age=31536000`
- `config.log_tags = [:request_id, :remote_ip]`
- `config.colorize_logging = false`
- `config.active_record.dump_schema_after_migration = false`

## Health Check Endpoint

- Rails 8 mounts `GET /up` by default (`Rails::HealthController`) — point Kamal/Thruster at it
- Add a richer `/health` only if you need to assert DB + cache + queue connectivity
- Skip authentication; return `200 OK` or `503 Service Unavailable`

```ruby
# config/routes.rb
get '/health', to: 'health#show' # optional richer probe; /up is built in
```

## Background Jobs & Graceful Shutdown

- Solid Queue is the default runner (replaces Redis/Sidekiq); Solid Cache + Solid Cable round out the trio
- Kamal sends SIGTERM and gives processes ~30s to drain — long-running jobs should `include ActiveJob::Continuable` and advance via `step` so they resume on the next boot

## Secrets Management

- Use `RAILS_MASTER_KEY` for credentials (never commit)
- Never commit `.env.production` or `.kamal/secrets`
- Rotate via `kamal env push` after updating the secret source
- Separate secrets per environment (staging vs production)

## Security Headers (Production)

- `config.force_ssl = true`
- HSTS: `expires: 1.year, subdomains: true, preload: true`
- CSP: `frame_ancestors :none`
- Set `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff` via middleware or CSP

## Database (Production)

- Use `DATABASE_URL` env var
- Set pool size: `pool: ENV.fetch('DB_POOL', 25)`
- `statement_timeout: 60000`, `lock_timeout: 10000` (milliseconds)
- `config.active_record.query_cache_enabled = true`

See `references/examples.md` for full configuration examples.
