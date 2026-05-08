# Antipattern: Non-RESTful Actions

## The smell
- `member do; post :publish; post :archive; post :feature; end` and similar in `routes.rb`
- Controllers with 8+ public actions, most of them custom verbs
- Pairs of verbs that are obviously create/destroy: `publish`/`unpublish`, `archive`/`unarchive`, `feature`/`unfeature`
- URLs that read RPC-ish (`POST /posts/:id/publish`)

## Why it hurts
- No conventions to lean on — every action is bespoke
- Authorization, redirects, and templates duplicate
- Form objects, params, and responses don't compose
- Discoverability suffers; URL shape gives no hint about behavior

## The fix
- **Each verb is a new resource.** Canonical DHH move
- `publish`/`unpublish` → `resource :publication, only: [:create, :destroy]`
- The new resource often *is* a real record (see "State as Records" in `rails-models`); even when it isn't, the routing convention pays off
- Controllers stay short and RESTful; URLs become `POST /posts/42/publication`

## When it's actually fine
Truly idempotent, parameter-less queries that don't fit a resource (`GET /search`) are okay. But a 4th custom member action means a hidden resource — find it.

## See also
- Rails routes reference: `../../rails/references/routes.md`
- Rails controllers reference: `../../rails/references/controllers.md`
- [fat-controller](fat-controller.md)

## Examples

### The smell

```ruby
# config/routes.rb
resources :posts do
  member do
    post :publish
    post :unpublish
    post :archive
    post :unarchive
    post :feature
    post :unfeature
    post :notify_subscribers
  end
end

class PostsController < ApplicationController
  def publish; end
  def unpublish; end
  def archive; end
  def unarchive; end
  def feature; end
  def unfeature; end
  def notify_subscribers; end
end
```

### The fix — each verb is a resource

```ruby
# config/routes.rb
resources :posts do
  resource :publication, only: [:create, :destroy] # publish/unpublish
  resource :archival,    only: [:create, :destroy]
  resource :feature,     only: [:create, :destroy]
end

class Posts::PublicationsController < ApplicationController
  before_action :set_post

  def create
    @post.publish
    redirect_to @post, status: :see_other
  end

  def destroy
    @post.unpublish
    redirect_to @post, status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
```

### URL shape

```
POST   /posts/42/publication   # publish
DELETE /posts/42/publication   # unpublish
POST   /posts/42/archival
DELETE /posts/42/archival
```
