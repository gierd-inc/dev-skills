---
name: rails-antipattern-homemade-keys-and-routes
description: Use when routes are hand-built around custom URL patterns or non-id keys, bypassing `resources` and `to_param`. From *Rails Antipatterns*.
---

# Antipattern: Homemade Keys and Routes

## The smell
- Hand-rolled `get "show_post/:slug", to: "posts#show_by_slug"` style routes
- Custom controller methods named `show_by_slug`, `user_posts`, `do_publish`
- `link_to "...", "/show_post/#{p.slug}"` (string URLs) because no helper exists
- Resourceful concepts wearing custom URLs

## Why it hurts
- No path/url helpers from `resources` — every link is bespoke
- `redirect_to @post` doesn't work
- Polymorphic helpers (`form_with model: @post`) break
- Authorization scoping (`current_user.posts.find(params[:id])`) becomes harder
- New devs can't predict URLs from models

## The fix
- Use `resources` and override `to_param` for slugs
- For nested keys, use `param:` on `resources`: `resources :users, param: :name`
- For "verbs," introduce a resource — see [non-restful-actions](../rails-antipattern-non-restful-actions/SKILL.md)
- Lookups: `Model.find(params[:id])` works because `params[:id]` is the slug after `to_param` override

## When it's actually fine
Marketing/landing pages with hand-crafted URLs (`/pricing`, `/about`) — they're not resources. The smell is *resourceful* concepts wearing custom URLs.

## See also
- [rails-routes](../../rails/rails-routes/SKILL.md)
- [non-restful-actions](../rails-antipattern-non-restful-actions/SKILL.md)

See `references/examples.md` for code samples.
