---
name: rails-security
description: use when implementing Rails authentication (Rails 8+ has_secure_password), authorization, CSRF protection, security headers, secure session config
---

# Rails Security

## Authentication (Rails 8+)

- Generate with `bin/rails generate authentication`
- Include `Authentication` module in `ApplicationController`
- Use `before_action :require_authentication`
- Track current user via `Current.user` (CurrentAttributes)
- Never store passwords in plaintext — use `has_secure_password`

## Session Security

- Session store: `:cookie_store` with `secure: Rails.env.production?`, `httponly: true`, `same_site: :lax`
- For API tokens: `has_secure_token :auth_token` + `regenerate_auth_token` for rotation

## Authorization

- Implement authorization logic in domain models: `editable_by?(user)`, `visible_to?(user)`
- Use `before_action` in controllers for consistent permission checks
- Return `head :forbidden` or redirect with `alert:` on failure
- Log authorization failures: `Rails.logger.warn "Unauthorized: user=#{id} ..."`
- Use `enum :role, { user: "user", admin: "admin" }, _prefix: true` for role-based checks

## CSRF Protection

- `protect_from_forgery with: :exception` (default for HTML controllers)
- For JSON/API endpoints: `protect_from_forgery with: :null_session, if: -> { request.format.json? }`

## XSS Prevention

- Rails auto-escapes HTML in views — do not bypass without cause
- `sanitize(content, tags: %w[p br strong em], attributes: [])` for user-supplied HTML
- Only use `.html_safe` for trusted admin content
- Set `Content-Security-Policy` with nonce-based script execution

## Security Headers

- `config.force_ssl = true` in production
- HSTS: `hsts: { expires: 1.year, subdomains: true, preload: true }`
- CSP nonce: `config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }`
- `frame_ancestors :none` to prevent clickjacking

## Rate Limiting (Rails 8+)

- `rate_limit to: 1000, within: 1.hour, by: -> { current_user&.id || request.ip }`
- Tighter limits on sensitive endpoints: login (5/min), password reset
- Return `429 Too Many Requests` with `retry_after`

## Input Validation

- Use strong parameters (`params.expect`) — see rails-controllers skill
- Validate file uploads: check `byte_size` and `content_type` in model validations
- Reject files exceeding size limit or outside allowed MIME types

## Security Monitoring

- Log authentication failures with email, IP, timestamp (no passwords)
- Log authorization failures with user ID, resource, action
- Use structured JSON log format for machine parsing

See `references/examples.md` for code samples.
