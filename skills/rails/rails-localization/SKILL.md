---
name: rails-localization
description: use when adding I18n translations, locale files, pluralization, time/number formatting
---

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

See `references/examples.md` for code samples.
