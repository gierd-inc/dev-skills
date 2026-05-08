# Rails Controllers — Code Samples

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
