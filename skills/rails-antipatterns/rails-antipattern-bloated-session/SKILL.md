---
name: rails-antipattern-bloated-session
description: Use when application code stuffs ActiveRecord objects, large hashes, or workflow state into `session[...]` instead of the database or `Current.*`. From *Rails Antipatterns*.
---

# Antipattern: Bloated Session

## The smell
- `session[:current_user] = @user` (whole AR object, not id)
- Cart contents, wizard state, or arbitrary form params stored in `session[...]`
- `CookieOverflow` errors in production
- Mysterious "everyone got logged out" deploys

## Why it hurts
- 4 KB cookie store limit — silent overflow
- Marshalling AR records freezes their schema; a deploy that adds a column raises on next request
- Sensitive data ends up in a cookie users can copy
- Workflow state in session is invisible to admins, jobs, and analytics

## The fix
- Store **ids only** in the session (`session[:user_id] = user.id`); reload via `User.find(...)`
- Use **`Current` attributes** for per-request context, set in a `before_action`
- For workflow state (carts, multi-step forms), persist a real **database record** (`Cart`, `Application`, `Draft`)
- Rails 8 `has_secure_password` + the new authentication generator already follow this pattern

## When it's actually fine
Tiny, ephemeral, non-sensitive flags (`session[:return_to]`, `session[:locale_override]`) are fine.

## See also
- [rails-security](../../rails/rails-security/SKILL.md)
- [rails-controllers](../../rails/rails-controllers/SKILL.md)

See `references/examples.md` for code samples.
