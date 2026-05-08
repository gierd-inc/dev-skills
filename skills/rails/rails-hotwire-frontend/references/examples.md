# Rails Hotwire Frontend — Code Examples

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
