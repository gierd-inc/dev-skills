# Rails Localization

## Setup & Defaults

- Set default locale in `config/application.rb`: `config.i18n.default_locale = :en`
- Declare available locales: `config.i18n.available_locales = %i[en es fr]`
- Enable fallback behavior: `config.i18n.fallbacks = true`

## Translation File Structure

- Use separate files per domain:
  - `config/locales/models/user.en.yml`
  - `config/locales/views/posts.en.yml`
  - `config/locales/controllers/sessions.en.yml`
- Nest keys by scope (`activerecord`, `views`, `controllers`, etc.)
- Never hardcode translations inline in views or controllers

## Lazy Lookups

- Use lazy lookup (`t ".key"`) inside views and controllers when inside scope
- Resolves relative to the current view path or controller action automatically

## Dates, Times, and Numbers

- Define format keys under `time.formats` or `number.format` in locale files
- Use `l(date, format: :long)` for localized date/time rendering
- Use `number_with_delimiter` for formatted numbers

## Dynamic Locale Switching

- Add `before_action :set_locale` in `ApplicationController`
- Read locale from `params[:locale]` with fallback to `I18n.default_locale`
- Add `scope "(:locale)"` to routes with a locale constraint regex
- Preserve locale in all generated links using `url_for(locale: :fr)`

## Examples

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
