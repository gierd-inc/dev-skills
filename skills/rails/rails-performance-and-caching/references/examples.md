# Rails Performance & Caching — Code Examples

## N+1 Prevention

```ruby
# Prevents N+1 — load author and comments in 2 queries
@posts = Post.includes(:author, :comments).limit(10)

# Filter without loading comments
@posts = Post.joins(:comments).where(comments: { approved: true }).distinct

# Limit columns
@users = User.select(:id, :name, :email).where(active: true)

# Counter cache
class Post < ApplicationRecord
  belongs_to :author, counter_cache: true
end
```

## Database Indexes

```ruby
class AddIndexesToPosts < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :author_id
    add_index :posts, :published_at
    add_index :posts, [:author_id, :published_at]  # composite
    add_index :posts, :slug, unique: true
  end
end
```

## Batch Processing

```ruby
# Memory-safe iteration
User.where(active: false).find_each(batch_size: 1000, &:send_reactivation_email)

# Bulk DB operations (skips callbacks)
Post.where(published: false).update_all(status: 'draft')

Post.insert_all([
  { title: 'Post 1', author_id: 1 },
  { title: 'Post 2', author_id: 2 }
])
```

## Fragment Caching

```erb
<!-- Basic fragment cache -->
<% cache [@user, "profile_summary"], expires_in: 1.hour do %>
  <div class="profile-summary">
    <h2><%= @user.name %></h2>
    <p>Posts: <%= @user.posts.published.count %></p>
  </div>
<% end %>

<!-- Conditional caching -->
<% cache_if user_signed_in?, [@post, "show"], expires_in: 1.hour do %>
  <%= render "post_content", post: @post %>
<% end %>
```

## Russian Doll Caching

```erb
<!-- Parent wraps children; child invalidation touches parent via touch: true -->
<% cache [@posts, "post_list"], expires_in: 15.minutes do %>
  <div class="post-list">
    <% @posts.each do |post| %>
      <% cache [post, "list_item"] do %>
        <article>
          <h3><%= link_to post.title, post %></h3>
          <% cache [post.author, "author_info"] do %>
            <span>By <%= post.author.name %></span>
          <% end %>
        </article>
      <% end %>
    <% end %>
  </div>
<% end %>
```

## Model Touch Associations & Cache Invalidation

```ruby
class Post < ApplicationRecord
  belongs_to :author, touch: true  # author.updated_at changes when post saved
  has_many :comments, dependent: :destroy, inverse_of: :post

  after_update_commit :expire_related_caches
  after_destroy_commit :expire_related_caches

  private

  def expire_related_caches
    Rails.cache.delete([author, "post_list"])
    Rails.cache.delete_matched("category/*/posts") if saved_change_to_category_id?
  end
end

class Comment < ApplicationRecord
  belongs_to :post, touch: true, inverse_of: :comments

  after_commit :update_post_caches

  private

  def update_post_caches
    Rails.cache.delete([post, "comment_count"])
    Rails.cache.delete([post, "latest_comments"])
  end
end
```

## Application-Level Caching (Rails.cache)

```ruby
# In controller
def trending
  @trending_posts = Rails.cache.fetch("trending_posts/#{Date.current}", expires_in: 1.hour) do
    Post.joins(:views)
        .where(views: { created_at: 1.week.ago.. })
        .group("posts.id")
        .order("COUNT(views.id) DESC")
        .limit(10)
        .includes(:author)
        .to_a
  end
end

# In model
def view_count_cached
  Rails.cache.fetch([self, "view_count"], expires_in: 15.minutes) { views.count }
end
```

## HTTP Caching with ETags

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    if stale?(etag: [@post, current_user&.cache_key], last_modified: @post.updated_at)
      @comments = @post.comments.includes(:author).published
    end
  end

  def index
    @posts = Post.published.includes(:author)
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour
  end
end

# Reusable helpers
class ApplicationController < ActionController::Base
  protected

  def cache_publicly(duration: 1.hour) = expires_in(duration, public: true)
  def cache_privately(duration: 5.minutes) = expires_in(duration, public: false)

  def cache_with_revalidation(duration: 10.minutes, stale_duration: 1.hour)
    expires_in duration, public: true,
               stale_while_revalidate: stale_duration,
               stale_if_error: stale_duration
  end
end
```

## Cache Warming Job

```ruby
class CacheWarmingJob < ApplicationJob
  queue_as :low_priority

  def perform
    warm_trending_posts
    warm_popular_authors
  end

  private

  def warm_trending_posts
    Rails.cache.delete("trending_posts/#{Date.current}")
    Post.trending  # populates cache via model scope
  end

  def warm_popular_authors
    Author.popular.find_each do |author|
      Rails.cache.fetch([author, "profile_stats"], expires_in: 2.hours) do
        { posts_count: author.posts.published.count, followers_count: author.followers.count }
      end
    end
  end
end
```

## Cache Store Configuration (Production)

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  connect_timeout: 30,
  read_timeout: 0.2,
  write_timeout: 0.2,
  reconnect_attempts: 1,
  error_handler: ->(method:, returning:, exception:) {
    Rails.logger.error "Cache error: #{exception.message}"
  }
}

config.active_record.query_cache_enabled = true
config.action_controller.enable_fragment_cache_logging = true
```

## Puma Configuration

```ruby
# config/puma.rb
workers_count = ENV.fetch('RAILS_MAX_WORKERS') { 2 }.to_i
threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }.to_i

workers workers_count if workers_count > 0
threads threads_count, threads_count

preload_app!

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

worker_timeout 60
worker_shutdown_timeout 30
bind "tcp://0.0.0.0:#{ENV.fetch('PORT') { 3000 }}"
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }
```

## Background Job with Performance Logging

```ruby
class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  around_perform do |job, block|
    start_time = Time.current
    block.call
  ensure
    Rails.logger.info({
      job_class: job.class.name,
      job_id: job.job_id,
      duration: Time.current - start_time,
      queue: job.queue_name
    }.to_json)
  end
end

# Batched job scheduling to avoid memory bloat
class EmailDigestJob < ApplicationJob
  def self.schedule_weekly_digest
    User.active.pluck(:id).each_slice(100) { |batch| perform_later(batch) }
  end
end
```

## Slow Query Logger

```ruby
module QueryAnalyzer
  def execute(sql, name = nil)
    start_time = Time.current
    result = super
    duration = Time.current - start_time

    if duration > 0.1
      Rails.logger.warn({ type: 'slow_query', sql: sql, duration: duration }.to_json)
    end

    result
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(QueryAnalyzer)
```

## Asset Optimization

```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.compress = true
config.assets.digest = true
config.asset_host = ENV['CDN_HOST'] if ENV['CDN_HOST'].present?
config.middleware.use Rack::Deflater
```

```erb
<!-- Responsive lazy image with srcset -->
<%= image_tag @post.featured_image.variant(resize_to_limit: [800, 600]),
    alt: @post.title,
    loading: "lazy",
    srcset: "#{url_for(@post.featured_image.variant(resize_to_limit: [400, 300]))} 400w,
             #{url_for(@post.featured_image.variant(resize_to_limit: [800, 600]))} 800w",
    sizes: "(max-width: 768px) 400px, 800px" %>
```
