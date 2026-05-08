# Rails: The Rails Way

## Core Tools (Always Use)
- `Minitest` for testing, `Fixtures` for test data
- `.html.erb` for views
- `has_secure_password` + `bin/rails g authentication` for auth
- RESTful controller actions only: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- `respond_to` in controllers (including `turbo_stream`)
- `broadcasts_refreshes` (or `broadcasts_to`) in models for Turbo Morph
- `params.expect(model_name: [...])` for strong params
- `model_params` private method for permitted params
- `db/seeds.rb` to seed new models
- `bundle update` before any code generation

## Never Use
- Inline JavaScript or CSS — use Stimulus and Tailwind
- `comment_<%= comment.id %>` — use `dom_id(comment)`
- `params.require(...).permit(...)`
- Non-resourceful routes
- Duplicate code — extract and share logic
- `respond_to` in `index` actions
- Devise, RSpec, FactoryBot, HAML, jQuery, React

## Architecture Philosophy

### Fat Models, Skinny Controllers
- Domain logic belongs in models — validations, callbacks, methods
- Controllers coordinate; they don't compute
- Business rules live in validations, callbacks, and model methods

### Convention Over Configuration
- Follow Rails conventions to eliminate decision fatigue
- Trust Rails' architectural decisions and sensible defaults
- Consistency enables team productivity

### Rails as Full-Stack Framework
- Server-side rendering by default — HTML over the wire
- Stimulus for interactive behavior, not application architecture
- Turbo for SPA-like experiences without SPA complexity
- Default to Turbo Morph (morphing) over frame replacements

### Service Objects: Last Resort
- Default to Rails' natural organization: rich models, concerns (`app/models/concerns/`, `app/controllers/concerns/`), domain models in `app/models/domain/`, form objects, query objects
- Service objects may have a legitimate use case (e.g., multi-model workflows, external API integration), but be prepared to justify it — reach for other object-oriented patterns first
- Existing service objects in the codebase are accepted; new ones require justification

## Code Style

### Ruby
- Use keyword arguments for clarity
- Apply `private`/`protected` consistently
- Use safe navigation (`&.`) to avoid nil errors
- Use snake_case for all identifiers
- Prefer `unless`, `||=`, and double quotes
- Follow the [Ruby Style Guide](https://rubystyle.guide)
- Symbol arrays with spaces inside brackets: `%i[ show edit update destroy ]`
- Indent `private` and its method bodies under the class:
  ```ruby
    private
      def set_message
        @message = Message.find(params[:id])
      end
  ```
- Use bang methods (`create!`, `update!`) for fail-fast paths
- Use expression-less `case` for chained conditionals over `if/elsif` ladders

### Methods
- Keep methods short (5-15 lines ideal)
- Prefer early returns and guard clauses
- Use `tap` for chaining with side effects
- Use `class_methods` block in concerns
- Public methods first, then `private` section

### Documentation
- Use RDoc-style `##` comments for public methods and classes
- Document edge cases and side effects
- Keep comments current with logic changes

## Code Organization
- One class/module per file
- Zeitwerk-compatible naming
- Organize by domain when appropriate (e.g., `/admin/`)
- Use descriptive names for methods, variables, and scopes

## Testing
- `ActiveSupport::TestCase`, `ActionDispatch::IntegrationTest`
- Fixtures over factories — fast, built-in, deterministic
- Assertions: `assert_difference`, `assert_enqueued_emails`, etc.
- Organize: `test/models/`, `test/controllers/`, `test/jobs/`, `test/system/`
- Favor full-stack request/system tests for controller behavior
- Every model, controller, job, helper, and view should be covered

## Performance
- Use database indexing effectively
- Eager loading to avoid N+1 queries (`includes`, `joins`, `select`)
- Fragment caching and Russian Doll caching strategies
- Use `ActiveJob` for time-consuming tasks

## Views
- Partials for reusable blocks
- Semantic HTML with accessibility-friendly markup
- ERB over HAML

## Tech Stack
- Ruby 3.4+, Rails Edge
- PostgreSQL or SQLite (project-dependent)
- Turbo & Stimulus (latest)
- TailwindCSS via RubyGem, DaisyUI for semantic CSS classes
- Propshaft (asset pipeline), Solid Queue/Cache/Cable (DB-backed)
- Kamal 2 + Kamal Proxy + Thruster for Docker-based deploys

## Reference Docs
- Rails Edge API: https://edgeapi.rubyonrails.org
- Rails Edge Guides: https://edgeguides.rubyonrails.org
- Turbo: https://turbo.hotwired.dev
- Stimulus: https://stimulus.hotwired.dev

## Examples

## RDoc-Style Method Comments

```ruby
## Calculates the user's full name, falling back to email if blank
# @return [String] user-facing name
def display_name
  name.presence || email
end
```

## Concern Structure

```ruby
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(published: true) }
    scope :draft, -> { where(published: false) }
  end

  def publish!
    update!(published: true)
  end

  def published?
    published
  end
end
```

## Controller Configuration Order

```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rejection :too_many_requests }

  before_action :ensure_user_exists, only: :new
end
```

## Strong Params (Modern)

```ruby
def user_params
  params.expect(user: [:email, :name])
end
```
