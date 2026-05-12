# Antipattern: Spaghetti SQL

## The smell
- The same business concept ("published, recent posts") expressed slightly differently across many call sites
- `where("...")` strings in controllers and views
- `find_by_sql` and raw `connection.execute` outside of migrations

## Why it hurts
- A schema or business-rule change requires hunting every call site
- Easy to drift (one place forgets `featured`, another forgets a tenancy filter)
- SQL fragments bypass scopes, joins, and security/tenancy filters
- Test setup mirrors the SQL instead of the intent

## The fix
- Push every query into a **named scope or class method** on the model
- Name scopes for the business term, not SQL: `published`, `featured`, `recent`, `reverse_chronologically`
- For complex queries that don't compose, use a **query object PORO** (`PostsForFeed`)
- Call sites read like sentences: `Post.published.featured.recent.limit(10)`

## When it's actually fine
One-off admin scripts and rake tasks can use ad-hoc queries. The smell is *duplication* and *leakage into request handlers*.

## See also
- Rails models reference: `../../rails/references/models.md`
- [n-plus-one-in-views](n-plus-one-in-views.md)
- Rails performance reference: `../../rails/references/performance-and-caching.md`

## Examples

### The smell

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

### The fix — composable scopes

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

### The fix — query object for complex composition

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
