# N+1 in Views — Code Samples

## The smell

```ruby
# PostsController
def index
  @posts = Post.recent
end
```

```erb
<% @posts.each do |post| %>
  <li><%= post.author.name %> — <%= post.comments.count %></li>
<% end %>
```

50 posts → 1 + 50 + 50 = **101 queries**.

## The fix — eager loading + counter cache

```ruby
class Post < ApplicationRecord
  belongs_to :author
  has_many :comments

  scope :recent,    -> { order(created_at: :desc) }
  scope :preloaded, -> { includes(:author) } # Gierd convention
end

class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end
```

```ruby
# Migration
add_column :posts, :comments_count, :integer, default: 0, null: false
Post.find_each { |p| Post.reset_counters(p.id, :comments) }
```

```ruby
# Controller
def index
  @posts = Post.preloaded.recent
end
```

```erb
<% @posts.each do |post| %>
  <li><%= post.author.name %> — <%= post.comments_count %></li>
<% end %>
```

50 posts → **2 queries**.

## Verifying in tests

```ruby
test "index does not N+1" do
  10.times { posts(:one).comments.create!(body: "x", author: users(:one)) }
  assert_queries(3) { get posts_path }
end
```
