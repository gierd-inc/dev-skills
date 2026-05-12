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
- Declare strict locals at the top of partials: `<%# locals: (user:, size: :base) -%>`. Only keyword args; positional/block args raise at render-time. Use `<%# locals: () %>` to disable locals entirely.

## Accessibility

- Always provide `alt:` on images; empty string for decorative
- Icon-only buttons need `aria: { label: "str" }`
- Use `required: true` on both label and input
- Use semantic HTML: `<button>` for actions, `<dialog>` for modals, `<label>` for inputs, `<nav>` for navigation

## Examples

## Simple Login Form (standalone components, no form builder)

```erb
<%= g_form_with(
  class: "flex flex-col gap-4",
  data: { turbo: false },
  url: sign_in_path,
) do |form| %>
  <h2 class="text-3xl"><%= t(".welcome_back") %></h2>

  <%= render_flash %>

  <fieldset>
    <%= g_input(
      label: t("shared.forms.email"),
      name: "email",
      placeholder: "name@example.com",
      required: true,
      size: :lg,
      type: "email",
    ) %>
  </fieldset>

  <fieldset class="flex flex-col gap-1.5">
    <%= g_password(
      label: t("shared.forms.password"),
      name: "password",
      placeholder: t("shared.forms.password"),
      required: true,
      size: :lg,
    ) %>

    <small class="text-sm">
      <%= link_to(
        t(".forgot_password"),
        password_reset_path,
        class: "text-text-link underline",
      ) %>
    </small>
  </fieldset>

  <%= g_button(
    t(".sign_in"),
    class: "w-full",
    size: :lg,
    type: "submit",
    variant: :primary,
  ) %>
<% end # `g_form_with` %>
```

## User Settings Form (multi-column grid with form builder)

```erb
<%= g_form_with(
  data: { controller: "settings-form" },
  model: [@account, @user],
) do |form| %>
  <%= render("application/form_errors", form_object: @user) %>

  <%= form.row(columns: 2) do %>
    <%= form.control do %>
      <%= form.label(:first_name) %>
      <%= form.text_field(:first_name, class: g_input_classes) %>
      <%= form.errors_for(:first_name) %>
    <% end %>

    <%= form.control do %>
      <%= form.label(:last_name) %>
      <%= form.text_field(:last_name, class: g_input_classes) %>
      <%= form.errors_for(:last_name) %>
    <% end %>
  <% end # form.row %>

  <%= form.row(columns: 3) do %>
    <%= form.control(span: 2) do %>
      <%= form.label(:email) %>
      <%= form.email_field(:email, class: g_input_classes) %>
      <%= form.errors_for(:email) %>
    <% end %>

    <%= form.control do %>
      <%= form.label(:status) %>
      <%= form.select(
        :status,
        [[t(".active"), true], [t(".inactive"), false]],
        {},
        class: g_select_classes,
      ) %>
      <%= form.errors_for(:status) %>
    <% end %>
  <% end # form.row %>

  <%= form.buttons(line: true) do %>
    <%= form.submit(t("shared.buttons.save_changes"), variant: :primary) %>
  <% end %>
<% end # g_form_with %>
```

## Form with Inline Errors

```erb
<%= g_form_with(model: @user) do |form| %>
  <%= render("application/form_errors", form_object: @user) %>

  <%= form.row do %>
    <%= form.control do %>
      <%= form.label(:email, required: true) %>
      <%= form.email_field(
        :email,
        class: g_input_classes,
        error: form.has_errors?(:email),
      ) %>
      <%= form.errors_for(:email) %>
    <% end %>
  <% end %>

  <%= form.buttons do %>
    <%= form.submit(t(".create_account"), variant: :primary) %>
  <% end %>
<% end # g_form_with %>
```

## Settings Page Layout

```erb
<%= g_settings_grid do %>
  <%= g_settings_section do %>
    <%= g_settings_section_header do %>
      <h2><%= t(".account_setup") %></h2>
      <p class="text-sm text-text-subtle"><%= t(".account_setup_description") %></p>
    <% end %>

    <%= g_settings_section_content do %>
      <%= g_box do %>
        <%= g_form_with(data: { controller: "settings-form" }, model: @user) do |form| %>
          <%= form.row do %>
            <%= form.control do %>
              <%= form.label(:name) %>
              <%= form.text_field(:name, class: g_input_classes) %>
              <%= form.errors_for(:name) %>
            <% end %>
          <% end %>

          <%= form.buttons(line: true) do %>
            <%= form.submit(t("shared.buttons.save_changes"), variant: :primary) %>
          <% end %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>

  <%= g_settings_section do %>
    <%= g_settings_section_header do %>
      <h2><%= t(".danger_zone") %></h2>
      <p class="text-sm text-text-subtle"><%= t(".danger_zone_description") %></p>
    <% end %>

    <%= g_settings_section_content do %>
      <%= g_box do %>
        <%= g_button_to(
          t(".delete_account"),
          account_path(@account),
          data: { turbo_confirm: t(".confirm_delete") },
          method: :delete,
          variant: :secondary,
        ) %>
      <% end %>
    <% end %>
  <% end %>
<% end # g_settings_grid %>
```

## Modal Dialog Patterns

### Remote content (Turbo Frame)

```erb
<%# Trigger — loads remote content into the layout's dialog turbo frame %>
<%= link_to(
  t(".terms_of_use"),
  terms_path,
  class: "text-text-link",
  data: {
    action: "click->dialog#handleClickOpen",
    turbo: true,
    turbo_frame: "g_dialog",
  },
) %>
```

### Inline content

```erb
<%# Trigger %>
<%= g_button(t(".confirm"), data: { action: "click->dialog#handleClickOpen" }) %>

<%# Content via content_for %>
<% content_for :g_dialog do %>
  <h2><%= t(".confirm_title") %></h2>
  <p class="text-text-subtle"><%= t(".confirm_description") %></p>
  <footer>
    <%= g_button(t(".cancel"), data: { action: "click->dialog#handleClickClose" }) %>
    <%= g_button_to(t(".delete"), resource_path(@resource), method: :delete, variant: :primary) %>
  </footer>
<% end %>
```

### Auto-open dialog (controller)

```ruby
def edit
  @g_dialog_options = { open: true }
end
```

### Dialog via turbo frame layout (controller renders into dialog)

```ruby
def download_dialog
  render(layout: "turbo_frame_g_dialog", template: "shared/download_dialog")
end
```

```erb
<%# View template — content only, no turbo frame wrapper needed %>
<h2><%= t(".heading") %></h2>
<p><%= t(".description") %></p>
<footer>
  <%= g_button(t("shared.buttons.cancel"), data: { action: "click->dialog#handleClickClose" }) %>
  <%= g_button(t(".confirm"), variant: :primary) %>
</footer>
```

## Sheet Pattern

### Remote content

```erb
<%= g_button_link_to(
  t(".edit"),
  edit_resource_path(@resource),
  data: {
    action: "click->sheet#handleClickOpen",
    turbo_frame: "g_sheet",
  },
) %>
```

### Sheet via turbo frame layout

```ruby
def help
  render(layout: "turbo_frame_g_sheet", template: "shared/help")
end
```

## Swap Controller (toggle show/hide)

```erb
<div data-controller="swap">
  <%= tag.div(
    data: {
      g_focus: "input",
      swap_target: "content",
    },
  ) do %>
    <%= g_input(label: t(".label"), name: "example", placeholder: t(".placeholder")) %>
  <% end %>

  <%= g_button("Toggle", data: { action: "click->swap#toggle" }) %>
</div>
```

## Button Tabs

Radio mode (form input):

```erb
<%= g_button_tabs(
  name: "report_period",
  value: report_period,
  list: [
    { icon: "calendar", text: t(".daily"), value: "daily" },
    { icon: "calendar", text: t(".weekly"), value: "weekly" },
    { icon: "calendar", text: t(".monthly"), value: "monthly" },
  ],
) %>
```

Link mode (navigation):

```erb
<%= g_button_tabs(
  value: request.path,
  list: [
    { href: overview_path, text: t(".overview") },
    { href: details_path, text: t(".details"), badge: @count },
  ],
) %>
```

## Data Grid

```erb
<%= g_data_grid(
  columns: [
    { group: t(".group_label"), id: "name", name: t(".column_name"), sort_by: "name" },
    { group: t(".group_label"), id: "email", name: t(".column_email"), sort_by: "email" },
    { can_hide: true, id: "status", name: t(".column_status") },
    { aria_label: t(".column_actions"), can_hide: false, id: "actions", name: "", shrink: true },
  ],
  other_label: t(".other_label"),
  pagination: render("shared/geared_pagination"),
  row_border: true,
  sticky_left: true,
  sticky_top: true,
  variant: :no_border,
) do %>
  <% @users.each do |user| %>
    <tr id="<%= dom_id(user) %>">
      <td><%= user.name %></td>
      <td><%= user.email %></td>
      <td>
        <%= g_badge(user.status.humanize, color: user.active? ? :green : :gray) %>
      </td>
      <td>
        <%= g_button_link_to(edit_user_path(user), aria: { label: t(".edit_user") }) do %>
          <%= g_icon("pencil", size: 16) %>
        <% end %>
      </td>
    </tr>
  <% end %>
<% end # g_data_grid %>
```

## Combo Box

```erb
<%# Single select with icon %>
<%= g_combo_box(
  icon: "cube",
  include_blank: true,
  items: @products.map { |p| { text: p.name, value: p.id, icon: "cube" } },
  name: "order[product_id]",
  placeholder: t(".select_product"),
) %>

<%# Multiselect %>
<%= g_combo_box(
  clearable: true,
  items: @tags.map { |tag| [tag.name, tag.id] },
  mode: :multiselect,
  name: "post[tag_ids][]",
  placeholder: t(".select_tags"),
  value: @post.tag_ids,
) %>

<%# Autocomplete %>
<%= g_combo_box(
  items: @users.map { |u| { text: u.name, value: u.id } },
  mode: :autocomplete,
  name: "assignment[user_id]",
  placeholder: t(".search_users"),
) %>
```

## Dropdown Menu

```erb
<%= g_button(
  t(".options"),
  aria: { controls: "user_menu" },
  data: { action: "click->menu#toggle" },
  id: "user_menu_trigger",
) %>

<%= g_menu(
  aria: { labelledby: "user_menu_trigger" },
  class_for_width: "w-55",
  id: "user_menu",
) do %>
  <%= g_menu_header(t(".actions")) %>
  <%= g_menu_item(t(".edit_profile"), href: edit_profile_path, icon: "pencil") %>
  <%= g_menu_item(t(".settings"), href: settings_path, icon: "cog") %>
  <%= g_menu_divider %>
  <%= g_menu_item(t(".sign_out"), data: { action: "click->session#destroy" }, icon: "arrow-right-on-rectangle") %>
<% end %>
```

## Date & Time

```erb
<%= g_date(@event.start_date) %>
<%= g_date(@event.start_date, show_day_of_week: true) %>
<%= g_datetime(@event.starts_at, show_year: true) %>
<%= g_relative_datetime(@comment.created_at) %>
<%= g_date_range(@event.start_date, @event.end_date) %>
<%= g_time_range(@event.starts_at, @event.ends_at) %>
```

## Date Picker

```erb
<%= g_date_picker(
  name: "event[start_date]",
  placeholder: t(".select_date"),
  value: @event.start_date&.iso8601,
) %>
```

## Slider

```erb
<%= g_slider(
  colors: ["--color-graphics-green", "--color-graphics-yellow", "--color-graphics-red"],
  marks: [0, 25, 50, 75, 100],
  max: 100,
  min: 0,
  name: "threshold[value]",
  step: 1,
  value: @threshold.value,
) %>
```

## Icon Usage

```erb
<%= g_icon("check", mode: :line, size: 16) %>
<%= g_icon("user", mode: :solid, size: 20) %>
<%= g_icon("star", mode: :color, size: 24, title: t(".favorite")) %>

<%# Icon-only button with accessibility %>
<%= g_button_link_to(edit_path, aria: { label: t(".edit_product") }) do %>
  <%= g_icon("pencil", size: 16) %>
<% end %>
```

## Toast

```erb
<%= g_toast(text: t(".changes_saved"), title: t(".success"), type: :success) %>

<%= g_toast(auto_close: 10, title: t(".error"), text: t(".something_went_wrong"), type: :alert) do %>
  <%= g_button(t(".retry"), data: { action: "click->retry#attempt" }, size: :sm) %>
<% end %>
```

## Turbo Frames & Streams

```erb
<%# Frame %>
<%= turbo_frame_tag("user_profile") do %>
  <%= render("users/profile", user: @user) %>
<% end %>

<%= link_to(t(".view_profile"), user_path(@user), data: { turbo_frame: "user_profile" }) %>

<%# Streams %>
<%= turbo_stream_from(@project) %>

<div id="<%= dom_id(@project, :tasks) %>">
  <% @project.tasks.each do |task| %>
    <%= tag.div(id: dom_id(task)) do %>
      <%= render("tasks/task", task: task) %>
    <% end %>
  <% end %>
</div>
```

## YARD Comment Style

```ruby
# Renders a badge with optional icon and tooltip.
#
# @param class_for_width [String]
# @param color [Symbol]
# @param icon [String]
# @param size [Symbol]
# @param text [String]
# @param tooltip [Hash]
# @param options [Hash]
# @param block [Proc]
# @return [String]
def g_badge(
  class_for_width: "w-90",
  color: :gray,
  icon: nil,
  size: :base,
  text: nil,
  tooltip: {},
  **options,
  &block
)
```

Section heading style: `##` not `# ===`

```ruby
##
# Example.
##
```

## Anti-patterns

Raw button (wrong):
```erb
<button class="btn btn-primary">Submit</button>
```
Use `g_button` instead.

Plain `form_with` (wrong):
```erb
<%= form_with(model: @user) do |form| %>
  <%= form.text_field(:name) %>
<% end %>
```
Use `g_form_with` with `g_input_classes`.

Raw Tailwind colors (wrong):
```erb
<p class="text-gray-700">Description</p>
```
Use `text-text-default` instead.

Image without alt (wrong):
```erb
<%= image_tag(product.image_url) %>
```
Use `alt: product.name`.

Select without classes (wrong):
```erb
<%= form.select(:status, options) %>
```
Use `class: g_select_classes`.
