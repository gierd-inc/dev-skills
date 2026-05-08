# Antipattern: Bloated Session

## The smell
- `session[:current_user] = @user` (whole AR object, not id)
- Cart contents, wizard state, or arbitrary form params stored in `session[...]`
- `CookieOverflow` errors in production
- Mysterious "everyone got logged out" deploys

## Why it hurts
- 4 KB cookie store limit — silent overflow
- Marshalling AR records freezes their schema; a deploy that adds a column raises on next request
- Sensitive data ends up in a cookie users can copy
- Workflow state in session is invisible to admins, jobs, and analytics

## The fix
- Store **ids only** in the session (`session[:user_id] = user.id`); reload via `User.find(...)`
- Use **`Current` attributes** for per-request context, set in a `before_action`
- For workflow state (carts, multi-step forms), persist a real **database record** (`Cart`, `Application`, `Draft`)
- Rails 8 `has_secure_password` + the new authentication generator already follow this pattern

## When it's actually fine
Tiny, ephemeral, non-sensitive flags (`session[:return_to]`, `session[:locale_override]`) are fine.

## See also
- Rails security reference: `../../rails/references/security.md`
- Rails controllers reference: `../../rails/references/controllers.md`

## Examples

### The smell

```ruby
# Whole AR object — breaks on schema change, may exceed cookie limit
session[:current_user] = @user

# Ever-growing hash
session[:cart] = { items: [...], total: ..., shipping: ... }

# Workflow state stuffed into session
session[:wizard_step_2_data] = params.to_unsafe_h
```

### The fix — id-only session + Current

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end
end

class SessionsController < ApplicationController
  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])
    if user
      session[:user_id] = user.id
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end
end
```

### The fix — workflow state as a real record

```ruby
# Instead of session[:cart], persist it
class Cart < ApplicationRecord
  belongs_to :user, optional: true # allow guest carts via cart_id in session
  has_many :line_items, dependent: :destroy
end

class CartsController < ApplicationController
  def show
    @cart = Cart.find_or_create_by(user: Current.user) if Current.user
    @cart ||= Cart.find_by(id: session[:cart_id]) || Cart.create.tap { |c| session[:cart_id] = c.id }
  end
end
```

### What's still fine

```ruby
session[:return_to] = request.fullpath
session[:locale]    = "en"
```
