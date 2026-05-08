---
name: rails-performance-and-caching
description: "use when optimizing Rails performance, database queries (N+1, includes/eager_load), HTTP caching, fragment/Russian doll caching, Solid Cache, app server tuning"
---

# Rails Performance & Caching

## Database Performance

- Use `includes(:assoc)` to prevent N+1 queries on index/list pages — this is the single most impactful rule
- Use `joins(:assoc)` when filtering without needing to load the association data
- Use `select(:id, :name, :email)` to limit columns fetched
- Use `counter_cache: true` on `belongs_to` for hot counts instead of `COUNT(*)` at render time
- Index foreign keys and frequently queried columns; use composite indexes for multi-column `WHERE`
- Use `find_each(batch_size: 1000)` for large datasets — never `.all` on unbounded sets
- Prefer `update_all`, `insert_all`, and `delete_all` for bulk operations (skips callbacks and AR object instantiation)
- Log and alert on queries slower than 100ms; use `relation.explain` / `EXPLAIN ANALYZE` to inspect plans
- Monitor N+1 patterns in development via `ActiveSupport::Notifications` or Bullet gem

## Fragment / Russian Doll Caching

- Cache expensive view partials with `<% cache [model, "key_suffix"], expires_in: 1.hour do %>`
- Include the model object as first cache key element — Rails uses `cache_key_with_version` automatically
- Russian doll: nest `<% cache post do %>` inside `<% cache [@posts, "list"] do %>` so child invalidation bubbles up
- Use `belongs_to :parent, touch: true` to propagate `updated_at` changes up the cache key chain
- Expire caches explicitly in `after_update_commit` / `after_destroy_commit` callbacks when `touch` isn't sufficient
- Use `Rails.cache.delete_matched("pattern/*")` for wildcard invalidation
- Warm critical caches via background jobs (`CacheWarmingJob`) scheduled before peak traffic
- Use `cache_if user_signed_in?, [...]` for conditional caching based on auth state
- For production: use SolidCache (database-backed) or Redis cache store

## HTTP Caching

- Use `stale?(etag: [@post, current_user&.cache_key], last_modified: @post.updated_at)` in controllers
- Use `expires_in duration, public: true` for anonymous content; `public: false` for user-specific content
- Use `stale_while_revalidate:` to serve stale content while the cache refreshes in the background
- Use `Rails.cache.fetch("key", expires_in: 1.hour) { expensive_query }` for application-level caching

## App Server / Puma Tuning

- Set `workers` to CPU core count; set `threads` to match `RAILS_MAX_THREADS` (default 5)
- Always call `preload_app!` in production; disconnect/reconnect the DB pool in `before_fork`/`on_worker_boot`
- Set `worker_timeout 60` and `worker_shutdown_timeout 30` to prevent hung workers
- Monitor memory per worker; log at 1% sampling rate using middleware; restart workers that exceed thresholds
- Use background jobs for any operation that could block a web worker (emails, heavy queries, file processing)
- Configure `config.active_job.queue_adapter` appropriately (Solid Queue, Sidekiq); add `retry_on` with exponential backoff
- Batch job inputs with `pluck(:id).each_slice(100)` to avoid memory bloat in workers

## Asset & Response Optimization

- Set `config.assets.compile = false`, `compress = true`, `digest = true` in production
- Use `config.asset_host = ENV['CDN_HOST']` to offload static asset delivery
- Add `Rack::Deflater` middleware for gzip compression
- Use `loading: "lazy"` and `srcset` on images; serve variants via ActiveStorage

See `references/examples.md` for code samples.
