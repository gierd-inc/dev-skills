# Spaghetti SQL — Code Samples

## The smell

```ruby
# PostsController#index
@posts = Post.where("published_at IS NOT NULL AND created_at > ?", 1.week.ago)
            .order("created_at DESC").limit(10)

# Admin::PostsController#index — almost the same, slightly different
@posts = Post.where("published_at IS NOT NULL").where("featured = ?", true)
            .order("created_at DESC")

# In a job
Post.find_by_sql(["SELECT * FROM posts WHERE published_at IS NOT NULL AND author_id = ?", id])
```

## The fix — composable scopes

```ruby
class Post < ApplicationRecord
  scope :published,               -> { where.not(published_at: nil) }
  scope :featured,                -> { where(featured: true) }
  scope :recent,                  ->(since = 1.week.ago) { where("created_at > ?", since) }
  scope :reverse_chronologically, -> { order(created_at: :desc) }
  scope :by_author,               ->(author) { where(author: author) }
end

# Call sites read like sentences:
Post.published.recent.reverse_chronologically.limit(10)
Post.published.featured.reverse_chronologically
Post.published.by_author(author)
```

## The fix — query object for complex composition

```ruby
class PostsForFeed
  def initialize(user, limit: 20)
    @user, @limit = user, limit
  end

  def results
    Post.published
        .where(author: @user.followed_authors)
        .or(Post.published.featured)
        .reverse_chronologically
        .limit(@limit)
  end
end
```
