---
name: rails-deployment
description: use when configuring Kamal deployment, Dockerfile for Rails, production environment, deploy.yml
---

# Rails Deployment

## Kamal Essentials

- Use Kamal for zero-downtime deployments to VPS/bare metal
- `kamal deploy` for production, `kamal deploy -d staging` for staging
- Secrets in `env.secret` list (pulled from environment, not committed)
- Clear env vars in `env.clear`

### deploy.yml Structure

```yaml
service: myapp
image: myapp

servers:
  web:
    hosts:
      - 192.168.1.1
    labels:
      traefik.http.routers.myapp.rule: Host(`myapp.com`)
      traefik.http.routers.myapp.tls: true
      traefik.http.routers.myapp.tls.certresolver: letsencrypt

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
  path: /health
  port: 3000
  max_attempts: 10
  interval: 5s

asset_path: /rails/public/assets
```

## Dockerfile

- Use multi-stage builds: `base` -> `gems` -> `app`
- Install only production gems (`--without development test`)
- Precompile assets with `SECRET_KEY_BASE=DUMMY`
- Run as non-root user (`rails:rails`)
- Expose port 3000, start with Puma

## Production Configuration

- `config.eager_load = true`
- `config.force_ssl = true`
- `config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?`
- Cache headers: `Cache-Control: public, max-age=31536000`
- `config.log_tags = [:request_id, :remote_ip]`
- `config.colorize_logging = false`
- `config.active_record.dump_schema_after_migration = false`

## Health Check Endpoint

- Expose `GET /health` (skip authentication)
- Check database connectivity and cache read/write
- Return `200 OK` or `503 Service Unavailable`

```ruby
# config/routes.rb
get '/health', to: 'health#show'
```

## Secrets Management

- Use `RAILS_MASTER_KEY` for credentials (never commit)
- Never commit `.env.production`
- Rotate secrets via Kamal's `kamal env push` workflow
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
