# Non-RESTful Actions — Code Samples

## The smell

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

## The fix — each verb is a resource

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

## URL shape

```
POST   /posts/42/publication   # publish
DELETE /posts/42/publication   # unpublish
POST   /posts/42/archival
DELETE /posts/42/archival
```
