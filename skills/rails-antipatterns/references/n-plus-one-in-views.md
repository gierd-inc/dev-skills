# Antipattern: N+1 Queries (especially in views)

## The smell
- Iterating a collection that calls `.author`, `.comments.count`, or other associations per row
- 50+ "SELECT ... WHERE id = ?" queries in dev log for one page render
- Bullet gem warnings
- `.count` inside a loop (where `counter_cache` or aggregation would do)

## Why it hurts
- Latency scales linearly with rows
- DB connection pressure
- Slow in dev, catastrophic in prod
- Often invisible until production data shape changes

## The fix
- **Eager-load** in the controller or scope: `Post.includes(:author).recent`
- Define a `preloaded` scope that bundles the standard eager-loads for that model — call it everywhere the view is rendered (Gierd convention from `rails-models`)
- For counts, use **`counter_cache`** or `LEFT JOIN ... GROUP BY` aggregation rather than `.count` in a loop
- Verify with **Bullet** in dev or `assert_queries(N)` in tests

## When it's actually fine
Small fixed-cap lists (e.g. menu of 5 categories) where the extra queries are immaterial. Even then, `includes` is cheap insurance.

## See also
- Rails performance reference: `../../rails/references/performance-and-caching.md`
- Rails models reference: `../../rails/references/models.md`
- [spaghetti-sql](spaghetti-sql.md)

## Examples

### The smell

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

### The fix — eager loading + counter cache

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

### Verifying in tests

```ruby
test "index does not N+1" do
  10.times { posts(:one).comments.create!(body: "x", author: users(:one)) }
  assert_queries(3) { get posts_path }
end
```
