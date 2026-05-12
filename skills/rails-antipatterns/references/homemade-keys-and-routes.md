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
- For "verbs," introduce a resource — see [non-restful-actions](non-restful-actions.md)
- Lookups: `Model.find(params[:id])` works because `params[:id]` is the slug after `to_param` override

## When it's actually fine
Marketing/landing pages with hand-crafted URLs (`/pricing`, `/about`) — they're not resources. The smell is *resourceful* concepts wearing custom URLs.

## See also
- Rails routes reference: `../../rails/references/routes.md`
- [non-restful-actions](non-restful-actions.md)

## Examples

### The smell

```ruby
# config/routes.rb
get  "show_post/:slug",      to: "posts#show_by_slug"
post "do_publish",           to: "posts#publish_action"
get  "u/:name/posts",        to: "users#user_posts"
post "comment_on/:post_slug", to: "comments#create_for_post"
```

```erb
<%= link_to post.title, "/show_post/#{post.slug}" %>
```

### The fix — resources with slug-aware to_param

```ruby
# config/routes.rb
resources :users, param: :name do
  resources :posts do
    resources :comments, only: [:create]
  end
end

class Post < ApplicationRecord
  belongs_to :user
  validates :slug, presence: true, uniqueness: { scope: :user_id }

  def to_param
    slug
  end
end

class PostsController < ApplicationController
  def show
    @user = User.find_by!(name: params[:user_name])
    @post = @user.posts.find_by!(slug: params[:id])
  end
end
```

```erb
<%= link_to post.title, [post.user, post] %>
<%= form_with model: [post.user, post] do |f| %>
  ...
<% end %>
```
