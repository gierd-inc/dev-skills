# Rails Controllers

## Structure
- Only RESTful public actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
- If a controller needs custom public methods, extract them to a new controller scoped to that feature
- Use `respond_to` in `create`, `update`, and `destroy` — not in `index` unless multi-format is needed

## REST Mapping (resources, not verbs)
- For non-CRUD actions, create a new resource rather than a custom verb on the existing controller
  - `POST /cards/:id/close` → `Cards::ClosuresController#create` (`POST /cards/:id/closure`)
  - `DELETE /cards/:id/close` → `Cards::ClosuresController#destroy`
  - `POST /cards/:id/archive` → `Cards::ArchivalsController#create`
- The new resource is often a real record (see "State as Records" in `references/models.md`), so the controller stays plainly RESTful

## Configuration Order
Always declare configuration in this order:
1. Authentication/authorization declarations
2. Rate limiting
3. Before actions

## Strong Parameters
- Use `params.expect(model_name: [...])` — this is the modern, more secure standard
- Never use `params.require(...).permit(...)`
- Always define a private `model_params` method for create/update actions

## Authentication & Authorization
- Use `allow_unauthenticated_access only: %i[new create]` from Rails built-in authentication
- Use `allow_bot_access only: %i[show]` (Rails 8 feature)
- Use `Current` object for user context
- Use descriptive method names for authorization checks
- Return appropriate HTTP status codes (`head :forbidden`, etc.)

## Browser Guard
- `ApplicationController` should declare `allow_browser versions: :modern` (default in new apps). Customize per-controller/action with `only:`/`except:` or a version hash. Blocked clients receive HTTP 406 from `public/406-unsupported-browser.html`.

## Rate Limiting
- Use declarative `rate_limit to:, within:, only:, with:` (Rails 7.2+)
- Always provide a custom rejection handler

## Response Formats
- `format.turbo_stream` for Turbo updates
- `format.md { render markdown: object }` (Rails 8.1+) — `object` must respond to `to_markdown`

## Turbo Stream Responses
- Use `respond_to` with `format.turbo_stream` in create/update/destroy
- Prefer Turbo stream updates over redirects when possible
- Use `turbo_stream.replace`, `turbo_stream.prepend`, etc.

## Error Handling
- Use controller-level `rescue_from` handlers in `ApplicationController`
- Provide user-friendly error responses
- Use semantic HTTP status codes: `:not_found`, `:forbidden`, `:unprocessable_entity`

## Before Actions
- Scope with `only:` or `except:` — never blanket before_actions
- Keep before_actions focused: set records, check auth
- Use `set_model` naming convention for record-finders

## Controller Concerns
- Shared controller logic (filters, auth, lookups) lives in `app/controllers/concerns/`
- Use `included do` block to register `before_action` hooks
- Include concerns explicitly in controllers

## Response Patterns
- Use `redirect_to @post, status: :see_other` after successful create/update
- Use `render :new, status: :unprocessable_entity` on failure
- Use semantic HTTP status codes consistently across similar actions

## Examples

## RESTful Structure with Authentication

```ruby
class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_post, only: %i[show edit update destroy]

  def index
    @posts = Current.user&.posts || Post.published
  end

  def show
    # @post set by before_action
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to @post, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.expect(post: [:title, :body, :status])
  end
end
```

## Configuration Order

```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rejection :too_many_requests }

  before_action :ensure_user_exists, only: :new
end
```

## Turbo Stream Response

```ruby
respond_to do |format|
  format.turbo_stream { render turbo_stream: turbo_stream.replace(@post) }
  format.html { redirect_to @post }
end
```

## Authorization Check

```ruby
def ensure_can_administer
  head :forbidden unless Current.user.can_administer?(@message)
end
```

## Error Handling in ApplicationController

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from UnauthorizedError, with: :unauthorized

  private

  def not_found
    render "errors/404", status: :not_found
  end

  def unauthorized
    redirect_to login_path, alert: "Please log in to continue"
  end
end
```

## Controller Concern

```ruby
# app/controllers/concerns/set_comment.rb
module SetComment
  extend ActiveSupport::Concern

  included do
    before_action :set_comment, only: %i[show edit update destroy]
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end
end

# Usage in controller
class CommentsController < ApplicationController
  include SetComment
end
```

## Before Actions

```ruby
before_action :set_post, only: %i[show edit update destroy]

private

def set_post
  @post = Post.find(params[:id])
end
```

## File Download Response

```ruby
def download
  send_file @document.file.path,
    filename: @document.filename,
    type: @document.content_type,
    disposition: 'attachment'
end
```

## Browser Guard

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
end

class LegacyApiController < ApplicationController
  allow_browser versions: { safari: 16.4, firefox: 121, ie: false }, only: :show
end
```

## Markdown Response

```ruby
def show
  @page = Page.find(params[:id])
  respond_to do |format|
    format.html
    format.md { render markdown: @page } # @page#to_markdown
  end
end
```
