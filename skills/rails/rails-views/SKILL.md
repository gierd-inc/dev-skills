---
name: rails-views
description: use when working with Rails views and the Gierd `g_*` design system component helpers (ERB templates, forms, layout components, data display)
---

# Rails Views & Gierd Design System

Helper source: `app/helpers/components/g_*_helper.rb`
Docs: `http://localhost:3000/design-system`

## Design System Overview

- Always use `t()` for user-facing strings
- Prefer `g_*` helpers over raw HTML elements when equivalent components exist
- Prefer tag helpers (`tag.div`, `tag.span`) over raw HTML for multiple attributes
- `g_*` helpers provide: ARIA, keyboard nav, dark mode via semantic color tokens, Stimulus integration

## Component Helper Signature

Standard parameter order: `g_component(text = nil, options = {}, &block)`

Common parameters: `aria`, `class`, `data`, `disabled`, `size` (`:base`, `:lg`, `:sm`, `:xs`), `variant` (`:default`, `:primary`, `:secondary`)

Use `*_classes` methods for styling without rendering: `g_button_classes`, `g_input_classes`, `g_select_classes`, `g_textarea_classes`, `g_label_classes`

## Form System

### g_form_with

Primary form helper using `GFormBuilder`. Parameters: `data`, `gap`, `layout` (`:vertical`/`:horizontal`), `model`, `size`, `url`

Form structure hierarchy:
```
g_form_with
└── form.row(columns: 2)
    └── form.control(span: 2)
        ├── form.label :field
        ├── form.text_field :field, class: g_input_classes
        └── form.errors_for :field
```

- `form.row(columns: N)` — grid container; no columns arg = single-column flex
- `form.control(span: N)` — field wrapper with column spanning
- `form.buttons(justify: :end, line: true)` — action button container
- `form.errors_for(:field)` — field-level error display
- `form.has_errors?(:field)` — conditional error styling
- `form.label(:field, required: true)` — shows asterisk with semantic HTML

Field helpers (overridden to use `g_*`):
- `form.text_field(:name, class: g_input_classes)`
- `form.email_field(:email, class: g_input_classes)`
- `form.password_field(:password, show_meter: true)`
- `form.select(:status, options, {}, class: g_select_classes)`
- `form.text_area(:description, class: g_textarea_classes)`
- `form.check_box(:agreed, class: "g-checkbox")`
- `form.radio_button(:type, "value", class: "g-radio")`

## Buttons

- `g_button(text, data: {}, disabled: false, size: :base, type: "button", variant: :primary, &block)`
- `g_button_link_to(text, url, size: :base, variant: :default, &block)`
- `g_button_to(text, url, method: :post, size: :base, variant: :default)`
- `g_button_tabs(list: [], name: nil, value: nil, &block)` — tab group (buttons, links, or radios)
- `g_button_tab(text, active:, badge:, disabled:, href:, icon:, name:, target:, value:)`

## Form Fields

- `g_input(class_for_width:, error:, icon_left:, icon_right:, label:, name:, required:, size:, type:)`
- `g_password(class_for_width:, label:, minlength:, name:, show_meter:, size:)`
- `g_select(class_for_width:, label:, list:, name:, size:, &block)`
- `g_textarea(class_for_width:, label:, name:, size:)`
- `g_combo_box(clearable:, icon:, include_blank:, items:, mode:, name:, placeholder:, readonly:, value:, variant:)` — searchable select; modes: nil, `:autocomplete`, `:multiselect`, `:search`
- `g_label(for:, label:, required:, size:)`

## Layout & Containers

- `g_box(size:, tag_name:, variant:)` — container with border and padding; variants: `:gray`, `:white`
- `g_settings_grid` → `g_settings_section` → `g_settings_section_header` + `g_settings_section_content`
  - Responsive 3-column grid (header: 1 col, content: 2 cols on desktop)

### Dialog and Sheet

Provided by layout partials (`_g_dialog.html.erb`, `_g_sheet.html.erb`). Do not call `g_dialog`/`g_sheet` directly — they render automatically from layout.

Remote content: trigger with `data: { action: "click->dialog#handleClickOpen", turbo_frame: "g_dialog" }`

Inline content: use `content_for :g_dialog` in the view

Auto-open: set `@g_dialog_options = { open: true }` in controller

Width override: `dialog_width` query param on trigger URL; unitless values get `px` appended

Dedicated layouts for controller-rendered content:
- `turbo_frame_g_dialog` — wraps in `<turbo-frame id="g_dialog">`
- `turbo_frame_g_sheet` — wraps in `<turbo-frame id="g_sheet">`

Do not use `layout: false` with a manual `<turbo-frame>` tag — loses CSS context and heading/footer styling.

## Menus & Overlays

`g_menu(aria:, class_for_width:, id:, render_inline:)` with:
- `g_menu_header(text)` — section label
- `g_menu_item(text, checked:, data:, href:, icon:, size:)` — button or link
- `g_menu_divider` — section separator
- `g_menu_block(&block)` — custom content

Reusable options menu partial: `app/views/shared/_options_menu.html.erb`

`g_tooltip(class_for_icon:, class_for_width:, icon:, render_inline:, title:, &block)`

## Data Display

- `g_data_grid(cache_key:, columns:, max_height:, min_height:, pagination:, q:, row_border:, row_click:, row_expand:, sticky_left:, sticky_top:, variant:)` — sortable table with Ransack; variants: `:no_border`, `:full`
- `g_badge(color:, icon:, size:, text:, &block)` — colors: `:blue`, `:gray`, `:green`, `:orange`, `:purple`, `:red`, `:turquoise`, `:yellow`
- `g_pill(active:, color:, href:, icon:, size:, text:, type:)`
- `g_icon(name, mode: :line, size: 24, title: nil)`
- `g_date(date, show_day_of_week:, show_month:, show_year:)` — client-side timezone via `local_time`
- Related: `g_date_range`, `g_datetime`, `g_datetime_range`, `g_relative_datetime`, `g_time`, `g_time_range`
- `g_loading_spinner(orientation:, size:, text:)`
- `g_vendor_logo(name, size: 20)`

## Utilities

- `g_classes(*args)` — merge/deduplicate Tailwind classes
- `g_style(hash)` — inline style string; snake_case keys → CSS properties
- `g_password_match(text_default:, text_negative:, text_positive:)`
- `g_slider(colors:, marks:, max:, min:, step:)`

Deprecated: `g_chart` — use ECharts via `app/javascript/echarts/` instead.

## YARD Standards

- Add YARD comments with types to all public methods in helper files
- Alphabetize `@param` tags; always include `@return [Type]`
- Use `##` style for section headings (not `# ===` box style)

## ERB Formatting

- Hash with multiple keys: one key-value per line with trailing comma
- Multi-keyword method calls: one arg per line with trailing comma before `)`
- Use `method(` with opening paren for multi-line calls

## Accessibility

- Always provide `alt:` on images; empty string for decorative
- Icon-only buttons need `aria: { label: "str" }`
- Use `required: true` on both label and input
- Use semantic HTML: `<button>` for actions, `<dialog>` for modals, `<label>` for inputs, `<nav>` for navigation

See `references/examples.md` for code samples.
