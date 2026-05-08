---
name: rails-helpers
description: Use when working with Rails view helpers, helper modules, or presentation logic in app/helpers/.
---

# Rails Helpers

## Organization
- Keep helpers focused on specific domains (navigation, styling, forms, media)
- Use descriptive method names
- Group related functionality together
- Avoid business logic in helpers — presentation only

## Module Structure
- One module per concern; match file name to module name (Zeitwerk)
- Place in `app/helpers/` and include automatically by Rails
- Use `content_tag`, `concat`, `link_to`, etc. from ActionView

## Styling and CSS Helpers
- Use helper methods for conditional CSS classes
- Support multiple class types and variants
- Keep class logic maintainable and extensible
- Use arrays + `join(' ')` to build class strings

## Status and State Indicators
- Create helpers for common status displays using `content_tag :span`
- Use semantic color coding with Tailwind classes
- Humanize status strings with `.humanize`
- Support `data:` attributes via options hash

## Link and Navigation Helpers
- Handle current page detection with `current_page?`
- Add accessibility: `rel: 'noopener noreferrer'` and `target: '_blank'` for external links
- Include `sr-only` spans for screen reader context on external links

## Form Helpers
- Add accessibility attributes by default (`aria-describedby` for errors)
- Add error CSS class automatically when field has errors
- Use `content_tag` with `concat` for composing complex markup
- Wrap fields in a div with error ID for `aria` linking

## Media and Asset Helpers
- Default to `loading: "lazy"` for images
- Include `alt` text always — never omit
- Handle missing avatars gracefully (initials fallback)
- Use `user.avatar.attached?` before rendering Active Storage images

## Stimulus Integration Helpers
- Build `data:` attribute hashes for Stimulus controllers
- Map keyword args to `data-controller-name-key-value` conventions
- Use `dasherize` for key names

## Internationalization Helpers
- Use `l(date, format: format)` for localized dates
- Use `time_ago_in_words` for relative timestamps
- Wrap `t()` calls to support fallback keys

See `references/examples.md` for code samples.
