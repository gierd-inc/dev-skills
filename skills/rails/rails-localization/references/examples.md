# Localization Examples

## Setting Default Locale

```ruby
# config/application.rb
config.i18n.default_locale = :en
config.i18n.available_locales = %i[en es fr]
config.i18n.fallbacks = true
```

## Scoped Translation Files

```yaml
# config/locales/models/user.en.yml
en:
  activerecord:
    models:
      user: "User"
    attributes:
      user:
        email: "Email Address"
```

```yaml
# config/locales/views/posts.en.yml
en:
  views:
    posts:
      index:
        title: "All Posts"
```

## Lazy Lookups in Views and Controllers

```erb
<%# app/views/posts/index.html.erb %>
<h1><%= t ".title" %></h1>
```

```ruby
# app/controllers/posts_controller.rb
def create
  if @post.save
    redirect_to @post, notice: t(".") # resolves to controllers.posts.create
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Date & Number Formatting

```yaml
# config/locales/en.yml
en:
  time:
    formats:
      long: "%B %d, %Y at %I:%M %p"
  number:
    format:
      delimiter: ","
      separator: "."
```

```erb
<%= l(@event.start_time, format: :long) %>
<%= number_with_delimiter(1250000) %>
```

## Dynamic Locale Selection

```ruby
# app/controllers/application_controller.rb
before_action :set_locale

def set_locale
  I18n.locale = params[:locale] || I18n.default_locale
end
```

```ruby
# config/routes.rb
scope "(:locale)", locale: /en|es|fr/ do
  resources :posts
end
```

```erb
<%# Locale switcher in layout %>
<%= link_to "Español", url_for(locale: :es) %>
<%= link_to "English", url_for(locale: :en) %>
```
