# Rails Helpers — Code Samples

## Application Helper

```ruby
module ApplicationHelper
  def page_title(title = nil)
    base_title = "My App"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def current_page_class(path)
    "current" if current_page?(path)
  end
end
```

## Styling and CSS Helpers

```ruby
module StyleHelper
  def button_classes(variant: :primary, size: :medium, **options)
    base_classes = %w[inline-flex items-center font-medium rounded]
    variant_classes = {
      primary: %w[bg-blue-600 text-white hover:bg-blue-700],
      secondary: %w[bg-gray-200 text-gray-900 hover:bg-gray-300],
      danger: %w[bg-red-600 text-white hover:bg-red-700]
    }
    size_classes = {
      small: %w[px-3 py-2 text-sm],
      medium: %w[px-4 py-2],
      large: %w[px-6 py-3 text-lg]
    }

    [base_classes, variant_classes[variant], size_classes[size]].flatten.compact.join(' ')
  end

  def card_classes(border: true, shadow: true)
    classes = %w[bg-white rounded-lg]
    classes << "border border-gray-200" if border
    classes << "shadow-sm" if shadow
    classes.join(' ')
  end
end
```

## Status Badge Helper

```ruby
module StatusHelper
  def status_badge(status, **options)
    classes = status_badge_classes(status)
    classes += " #{options[:class]}" if options[:class]

    content_tag :span, status.humanize,
                class: classes,
                data: options[:data]
  end

  private

  def status_badge_classes(status)
    base = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    case status.to_s
    when 'active', 'published', 'completed'
      "#{base} bg-green-100 text-green-800"
    when 'pending', 'draft'
      "#{base} bg-yellow-100 text-yellow-800"
    when 'inactive', 'cancelled'
      "#{base} bg-red-100 text-red-800"
    else
      "#{base} bg-gray-100 text-gray-800"
    end
  end
end
```

## Navigation Helpers

```ruby
module NavigationHelper
  def nav_link_to(name, path, **options)
    classes = nav_link_classes(path, options.delete(:class))
    link_to name, path, class: classes, **options
  end

  def external_link_to(name, url, **options)
    options[:target] ||= '_blank'
    options[:rel] ||= 'noopener noreferrer'

    link_to url, **options do
      concat name
      concat " "
      concat content_tag(:span, "↗", class: "external-icon", aria: { hidden: true })
      concat content_tag(:span, "(opens in new window)", class: "sr-only")
    end
  end

  private

  def nav_link_classes(path, additional_classes = nil)
    base_classes = "nav-link"
    base_classes += " nav-link--active" if current_page?(path)
    base_classes += " #{additional_classes}" if additional_classes
    base_classes
  end
end
```

## Form Helper with Accessibility

```ruby
module FormHelper
  def form_field(form, field, **options)
    field_type = options.delete(:as) || :text_field
    wrapper_class = options.delete(:wrapper_class) || "form-field"
    label_text = options.delete(:label) || field.to_s.humanize

    content_tag :div, class: wrapper_class do
      concat form.label(field, label_text, class: "form-label")
      concat form.send(field_type, field, form_field_options(form, field, options))
      concat form_field_errors(form, field) if form.object.errors[field].any?
    end
  end

  private

  def form_field_options(form, field, options)
    base_options = {
      class: "form-control",
      aria: {
        describedby: "#{field}_error" if form.object.errors[field].any?
      }
    }
    base_options[:class] += " form-control--error" if form.object.errors[field].any?
    base_options.merge(options)
  end

  def form_field_errors(form, field)
    return unless form.object.errors[field].any?
    content_tag :div, class: "form-error", id: "#{field}_error" do
      form.object.errors[field].first
    end
  end
end
```

## Media and Avatar Helpers

```ruby
module MediaHelper
  def responsive_image(source, alt_text, **options)
    sizes = options.delete(:sizes) || "(max-width: 768px) 100vw, 50vw"
    srcset = options.delete(:srcset)
    loading = options.delete(:loading) || "lazy"

    image_tag source,
              alt: alt_text,
              sizes: sizes,
              srcset: srcset,
              loading: loading,
              **options
  end

  def avatar_image(user, size: :medium, **options)
    size_classes = { small: "w-8 h-8", medium: "w-12 h-12", large: "w-16 h-16" }
    classes = "rounded-full object-cover #{size_classes[size]}"
    classes += " #{options[:class]}" if options[:class]

    if user.avatar.attached?
      image_tag user.avatar,
                alt: "#{user.name}'s profile picture",
                class: classes
    else
      content_tag :div,
                  user.name.first&.upcase || "?",
                  class: "#{classes} bg-gray-300 flex items-center justify-center text-gray-600 font-medium"
    end
  end
end
```

## Stimulus Integration Helpers

```ruby
module StimulusHelper
  def stimulus_controller(name, **data)
    data_attrs = { controller: name }

    data.each do |key, value|
      case key
      when /(.+)_value$/
        data_attrs["#{name}-#{$1}-value"] = value
      when /(.+)_class$/
        data_attrs["#{name}-#{$1}-class"] = value
      when /(.+)_target$/
        data_attrs["#{name}-target"] = value
      else
        data_attrs["#{name}-#{key.to_s.dasherize}"] = value
      end
    end

    { data: data_attrs }
  end

  def auto_submit_form(**options)
    delay = options.delete(:delay) || 500
    stimulus_controller("auto-submit", delay_value: delay)
  end

  def confirmation_button(**options)
    message = options.delete(:message) || "Are you sure?"
    stimulus_controller("confirmation", message_value: message)
  end
end
```

## Internationalization Helpers

```ruby
module LocaleHelper
  def t_with_default(key, default_key, **options)
    t(key, **options.merge(default: t(default_key, **options)))
  end

  def localized_date(date, format: :default)
    return unless date
    l(date, format: format)
  end

  def localized_time_ago(time)
    return unless time
    "#{time_ago_in_words(time)} #{t('helpers.time.ago')}"
  end

  def rich_t(key, **options)
    translation = t(key, **options)
    simple_format(translation)
  end
end
```
