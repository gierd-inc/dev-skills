# Action Text Examples

## Rich Text Field on a Model

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_rich_text :body
  validates :body, presence: true
end
```

## Rendering in a View

```erb
<%# app/views/posts/show.html.erb %>
<%= @post.body.to_trix_html %>
```

```erb
<%# app/views/posts/index.html.erb %>
<%= truncate(@post.body.to_plain_text, length: 200) %>
```

## Accessing Embedded Attachables

```ruby
@post.body.attachables.each do |attachable|
  puts attachable.class.name
end
```

## Sanitizing Rich Content

```ruby
sanitize(@post.body.to_html, tags: %w(p strong em a), attributes: %w(href))
```

## Embedding a Model (Manual Insertion)

```ruby
ActionText::Attachable.from_attachable(Comment.first)
```
