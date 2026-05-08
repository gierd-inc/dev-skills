# Rails Hotwire Frontend

## Turbo

### General Rules

- Prefer Turbo Morph for dynamic partial updates — add `<%= turbo_refreshes_with method: :morph, scroll: :preserve %>` to `application.html.erb`
- Use `dom_id(model)` for all DOM targeting; avoid hard-coded DOM IDs
- Avoid page reloads when Turbo Stream or Frame can handle the change
- Do not nest Turbo Frames unless parent and child actions are clearly separated

### Turbo Streams vs Frames

- Use **Turbo Streams** for in-place updates (lists, tables, comment feeds)
- Use **Turbo Frames** for isolated page fragments with independent rendering (modals, tabs)

Controller pattern:
```ruby
respond_to do |format|
  format.turbo_stream { render turbo_stream: turbo_stream.replace(@post) }
  format.html { redirect_to posts_path }
end
```

Default to `turbo_stream.replace`; use `prepend`/`append` when ordering matters.

### Model Broadcasts

```ruby
broadcasts_to ->(post) { [post.user, :posts] }, inserts_by: :prepend
```

Use `broadcast_replace_later_to` for after-commit async updates.

### Defaults

- Controllers: always use `respond_to` blocks with `turbo_stream`
- Views: use partials and `turbo_stream_from` where applicable
- Use `dom_id(record)` and `dom_class(record)`, never hard-coded IDs

## Stimulus / JavaScript

### File Conventions

- `*.js` for app files, `*.mjs` for config and tests
- `snake_case.js` for app files, `snake_case.test.mjs` for tests
- `PascalCase` classes, `camelCase` functions/variables, `UPPER_SNAKE_CASE` shared constants
- Alphabetize imports, object keys, method names when order does not affect logic

### Directory Structure

- `app/javascript/application.js` — entry point
- `app/javascript/controllers/*_controller.js` — Stimulus controllers
- `app/javascript/echarts/` — ECharts config (use for new charts)
- `app/javascript/charts/` — Legacy Chartkick (do not add new)
- `app/javascript/utils/` — shared utilities
- `app/views/inline_javascript/` — preload scripts embedded in HTML

### Code Style

- Always use curly braces for `if`, even single-line
- No nested ternaries; prefer early returns over `else`
- Use `const` by default, `let` only when reassigned, never `var`
- Use arrow functions for callbacks
- Use double quotes and semicolons
- Use `===`/`!==` (never `==`/`!=`)
- Use template literals over concatenation
- Use `Boolean()` not `!!` for boolean coercion
- Use optional chaining `?.` when no-op is acceptable
- Math comparisons: put lower value on left; use `<=` or `<`, never `>=` or `>`

### Controller Organization Order

1. Imports
2. Shared types (`@typedef`)
3. Shared constants (`const EVENT_*`)
4. `static targets = [...]`
5. `static values = {...}`
6. Public fields (with `@type` JSDoc, default value)
7. Private fields (`#fieldName`) — avoid unless restricting external access
8. `initialize()` — bind `this` context
9. `connect()` — setup, add events
10. `*TargetConnected()` — per-target setup
11. `disconnect()` — cleanup
12. `*TargetDisconnected()` — per-target cleanup
13. `addEvents()` / `removeEvents()`
14. `addObserver()` / `removeObserver()`
15. Public methods (alphabetized)
16. Private methods (alphabetized)

Declare all instance fields at top of class with default value and `/** @type {Type} */` annotation.

### Memory Management

Always clean up in `disconnect()`:
- Remove event listeners added in `connect()`
- Disconnect observers (`resizeObserver?.disconnect()`)
- Clear timers (`clearInterval`, `clearTimeout`)
- Destroy chart instances

Pattern: call `removeEvents()` at start of `addEvents()` to prevent double-registration.

### Stimulus in ERB

Use `tag.div` with `data:` hash. Rails converts `snake_case` keys to `kebab-case`:
- `data-controller="foo"` → `data: { controller: "foo" }`
- `data-foo-bar-value="x"` → `data: { foo_bar_value: "x" }`
- `data-action="click->foo#method"` → `data: { action: "click->foo#method" }`

Use `g_classes` helper for Tailwind in ERB (see Tailwind section).

### Cross-Controller Events

Use `window.grips` namespace. Dispatch on `document`. See examples below for pattern.

### Utility: getController

`import { getController } from "utils/get_controller"` — look up Stimulus controller instance. Use as last resort; prefer Stimulus actions over direct method calls.

### Security

- Avoid inline event handlers; use Stimulus actions
- Sanitize user input before processing
- Use CSRF tokens via `getCsrfToken()` from `utils/get_csrf_token` for fetch requests

### JSDoc Standards

- Add JSDoc with types for all functions
- Blank line between description and first `@param`
- Spaces around `|` in unions: `{string | null}`; spaces after commas in generics
- Indicate allowed values: `@param {"plural" | "singular"} mode`
- Omit redundant descriptions
- For 3+ params, use object destructuring with `@typedef`
- Section headings: `/** Example. */` block style (not `// ===` box style)

### Testing (Vitest)

- Use `appSetup()` from `test/javascript/_setup/app_setup.mjs`
- HTML fixtures: `test/javascript/_html/*_controller.html`
- Test order: get elements → assertions → fireEvent → assertions → cleanup
- `describe` string = class name: `"FooController"`; nested: `"ClassName: qualifier"`
- `test` strings: bare verb phrases: `"enables button after form submit"`
- Coverage ignore: `/* v8 ignore start */` / `/* v8 ignore stop */` as pair; never `/* v8 ignore next */`

## Tailwind

### Semantic Colors — Always Use These

Never use raw Tailwind palette colors. Use semantic tokens that auto-adjust for dark mode.

| Avoid | Use instead |
| --- | --- |
| `bg-white` | `bg-background-default` |
| `bg-gray-50` | `bg-background-depth-1` |
| `bg-gray-100` | `bg-background-depth-2` |
| `bg-gray-200` | `bg-background-depth-4` |
| `bg-gray-100` (hover) | `bg-background-hover` |
| `bg-blue-50` | `bg-background-blue-light` |
| `bg-green-50` | `bg-background-green-light` |
| `bg-red-50` | `bg-background-error` |
| `text-gray-700`, `text-gray-800` | `text-text-default` |
| `text-gray-500`, `text-gray-600` | `text-text-subtle` |
| `text-gray-900`, `text-black` | `text-text-bold` |
| `text-blue-600` | `text-text-link` |
| `text-green-600` | `text-text-green` |
| `text-red-600` | `text-text-error` |
| `text-white` (dark bg) | `text-text-invert-bold` |
| `border-gray-100`, `border-gray-200` | `border-border-light` |
| `border-gray-300` | `border-border-medium` |
| `border-gray-400+` | `border-border-dark` |
| `border-blue-500` | `border-border-focus` |
| `border-red-500` | `border-border-error` |
| `fill-gray-400` | `fill-icon-subtle` |
| `fill-gray-600` | `fill-icon-default` |
| `fill-gray-900` | `fill-icon-bold` |
| `fill-red-500` | `fill-icon-error` |

Full token list: `app/assets/tailwind/theme/tailwind.css`

Theme pipeline: Figma variables → `figma-tailwind-converter` → CSS files in `app/assets/tailwind/theme/` (auto-generated, never edit manually)

### Class Merging

Use `g_classes(*args)` — wraps `tailwind_merge`. Last-in-wins for conflicts. Accepts arrays, strings; auto-filters `nil` and booleans.

`g_*_classes` helpers return class strings for use with Rails form helpers: `g_input_classes`, `g_select_classes`, `g_textarea_classes`, `g_label_classes`

### CSS Custom Properties in JavaScript

Use `var(--color-{category}-{token})`. Categories: `background`, `border`, `button`, `graphics`, `icon`, `text`.

```js
// Correct.
element.style.color = "var(--color-text-subtle)";
element.style.fill = "var(--color-icon-default)";
```

Do not guess token names (`--color-text-muted`, `--color-gray-500`, `--color-fill-icon-bold` do not exist).

### Writing Classes in Views

- `g-*` component marker classes first on their own line
- Always use `g_classes()` to merge — never string concatenation
- Base classes next, then modifiers (`hover:`, `md:`, `sm:`)
- Multi-line when more than three classes
- Prefer ERB helpers over HTML when using `g_classes`

### Patterns to Avoid

- Raw Tailwind colors (`bg-blue-600`, `bg-white`, `text-gray-*`)
- Hallucinated token names — check the table above or `app/assets/tailwind/theme/`
- String concatenation (`"#{base} #{extra}"`) — use `g_classes()`
- Bootstrap-style class names (`btn`, `card`, `form-control`, `nav-link`)
- Tailwind v3 syntax — project uses v4 with CSS config (`app/assets/tailwind/config.css`)
- Editing `app/assets/tailwind/components/` without front-end team review
- Editing `app/assets/tailwind/theme/` — auto-generated from Figma

## Examples

## Turbo

### Turbo Stream Controller Response

```ruby
def update
  @post.update(post_params)
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.replace(@post) }
    format.html { redirect_to @post }
  end
end
```

### Turbo Morph Layout Setup

```erb
<%# application.html.erb — required for morph %>
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
```

Morph controller response:

```ruby
def show
  respond_to do |format|
    format.turbo_stream
    format.html
  end
end
```

### Turbo Frame

```erb
<turbo-frame id="post_1">
  <%= render @post %>
</turbo-frame>

<%# Lazy-loaded frame %>
<turbo-frame id="modal" src="/posts/new" loading="lazy">
  Loading…
</turbo-frame>
```

### Disable Turbo Drive

```erb
<%= link_to "Sign Out", sign_out_path, data: { turbo: false } %>
```

### Model Broadcasts

```ruby
class Comment < ApplicationRecord
  belongs_to :post

  broadcasts_to ->(comment) { [comment.post, :comments] }, inserts_by: :prepend
end

class Notification < ApplicationRecord
  after_update_commit -> { broadcast_replace_later_to user }
end
```

### Turbo Stream from View

```erb
<%= turbo_stream_from(@project) %>

<div id="<%= dom_id(@project, :tasks) %>">
  <% @project.tasks.each do |task| %>
    <%= tag.div(id: dom_id(task)) do %>
      <%= render("tasks/task", task: task) %>
    <% end %>
  <% end %>
</div>
```

## Stimulus Controller (full structure)

```js
import { Controller } from "@hotwired/stimulus";

/**
 * @typedef {{
 *  name: string,
 *  size: number,
 * }} IFile
 */

const EVENT_EXAMPLE = "grips:event-example";

/**
 * Example controller.
 *
 * @export
 * @class
 * @extends {Controller}
 */
export default class extends Controller {
  // data-IDENTIFIER-target="name"
  static targets = ["output"];

  // data-IDENTIFIER-NAME-value="etc"
  static values = {
    id: String,
    noData: { default: "No data", type: String },
  };

  /** @type {Map<string, string>} */
  formDataMap = new Map();

  /** @type {ResizeObserver | null} */
  resizeObserver = null;

  /**
   * Called once per instance.
   *
   * @returns {void}
   */
  initialize() {
    this.handleExample = this.handleExample.bind(this);
    this.handleResize = this.handleResize.bind(this);
  }

  /**
   * Called when DOM mounts.
   *
   * @returns {void}
   */
  connect() {
    this.addEvents();
  }

  outputTargetConnected() {
    // Per-target setup
  }

  /**
   * Called when DOM unmounts.
   *
   * @returns {void}
   */
  disconnect() {
    this.removeEvents();
    this.removeObserver();
  }

  addEvents() {
    this.removeEvents();
    document.addEventListener(EVENT_EXAMPLE, this.handleExample);
  }

  removeEvents() {
    document.removeEventListener(EVENT_EXAMPLE, this.handleExample);
  }

  addObserver() {
    this.removeObserver();
    this.resizeObserver = new ResizeObserver(this.handleResize);
    this.resizeObserver.observe(this.element);
  }

  removeObserver() {
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
  }

  /**
   * @param {Event} event
   * @returns {void}
   */
  handleExample(event) {
    // Event handler
  }

  /**
   * @param {Event} event
   * @returns {void}
   */
  handleResize(event) {
    if (this.element.checkVisibility()) {
      // Resize logic
    }
  }
}
```

## Stimulus in HTML

```html
<div
  class="foo bar"
  data-controller="foo"
  data-foo-bar-value="etc"
  data-foo-target="etc">
  <button
    data-action="click->foo#handleClick"
    type="button">
    Button text
  </button>
</div>
```

## Stimulus in ERB

```erb
<%= tag.div(
  class: g_classes("
    foo
    bar
  "),
  data: {
    controller: "foo",
    foo_bar_value: "etc",
    foo_target: "etc",
  },
) do %>
  <%= g_button(
    t("button_text"),
    data: {
      action: "click->foo#handleClick",
    },
  ) %>
<% end %>
```

## Cross-Controller Event Broadcast

```js
const EVENT_DIALOG_RELOAD = "grips:dialog-reload";

window.grips ||= {};

/**
 * Broadcasts a "dialog reload" event.
 *
 * @param {string} url
 * @returns {void}
 */
window.grips.dialogReload = (url = "") => {
  document.dispatchEvent(
    new CustomEvent(EVENT_DIALOG_RELOAD, {
      detail: { url },
    })
  );
};
```

## JSDoc with Object Params

```js
/**
 * Example with object params.
 *
 * @param {{
 *  value1: string,
 *  value2: string,
 *  value3: string,
 * }} props
 * @returns {void}
 * @throws {Error} When invalid.
 */
const foo = ({ value1, value2, value3 }) => {
  if (!value1 || !value2 || !value3) {
    throw new Error("Missing required values");
  }
};
```

## Test File Structure (Vitest)

```js
import { appSetup } from "setup/app_setup";
import { beforeEach, describe, expect, test } from "vitest";
import { fireEvent } from "@testing-library/dom";
import FooController from "controllers/foo_controller";

describe("FooController", () => {
  /**
   * Constants.
   */

  const EXAMPLE_IF_NEEDED = "etc";

  // Before.
  beforeEach(() => {
    appSetup({
      controllers: { foo: FooController },
      html: "foo_controller.html",
    });
  });

  test("toggles active state on click", () => {
    // Get elements.
    const target = document.querySelector('[data-foo-target="output"]');

    // Test assertions.
    expect(target.dataset.gActive).toBe(String(false));

    // Fire event.
    fireEvent.click(target);

    // Test assertions.
    expect(target.dataset.gActive).toBe(String(true));
  });
});
```

## Coverage Ignore Patterns

```js
/* v8 ignore start */
if (isGuardCondition) {
  return;
}
/* v8 ignore stop */

try {
  // Logic
} /* v8 ignore start */ catch (error) {
  this.handleError(error);
} /* v8 ignore stop */
```

## Tailwind: Writing Classes in Views

```erb
<%= tag.div(
  class: g_classes(
    # Unconditional.
    "
      g-my-component
      bg-background-default
      border
      border-border-light
      flex
      flex-col
      gap-5
      rounded-lg
      hover:border-border-medium
      md:p-8
      sm:p-6
    ",
    # Conditional.
    ("
      opacity-40
      pointer-events-none
    " if disabled),
  ),
) do %>
  Content
<% end %>
```

## Tailwind: g_classes Merge Examples

```ruby
g_classes("base-class", ("opacity-40" if disabled))  # Conditional
g_classes("flex", nil, false, "gap-4")               # "flex gap-4"
g_classes("m-0 mx-5 my-5")                          # "mx-5 my-5"
g_classes("px-5 py-5 p-0")                          # "p-0"
```

## Tailwind: g_*_classes with Form Helpers

```ruby
f.label(:name, t("label_text"), class: g_label_classes(size: :sm))

f.select(:type, [], {}, class: g_select_classes(size: :sm))

f.text_area(:name, class: g_textarea_classes(size: :sm))

f.text_field(:name, class: g_input_classes(size: :sm))
```

## Tailwind: CSS Custom Properties in JavaScript

```js
// Correct.
element.style.color = "var(--color-text-subtle)";
element.style.fill = "var(--color-icon-default)";
element.style.backgroundColor = "var(--color-background-default)";

// Wrong — these do not exist.
element.style.color = "var(--color-text-muted)";
element.style.color = "var(--color-gray-500)";
element.style.fill = "var(--color-fill-icon-bold)";
```
