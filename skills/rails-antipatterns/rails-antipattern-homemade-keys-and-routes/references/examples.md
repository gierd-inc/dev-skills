# Homemade Keys and Routes — Code Samples

## The smell

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

## The fix — resources with slug-aware to_param

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
