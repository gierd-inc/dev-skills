# Rails Security Examples

## ApplicationController with Authentication

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  before_action :require_authentication
  protect_from_forgery with: :exception

  private

  def set_current_request_details
    Current.user = current_user
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end
end
```

## Session Store Configuration

```ruby
# config/application.rb
config.session_store :cookie_store,
  key: '_app_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

## Model Authorization Methods

```ruby
class Post < ApplicationRecord
  def editable_by?(user)
    user == self.user || user.admin?
  end

  def visible_to?(user)
    published? || editable_by?(user)
  end
end

class User < ApplicationRecord
  enum :role, { user: "user", admin: "admin", moderator: "moderator" }, _prefix: true

  def can_edit?(resource)
    case resource
    when Post    then role_admin? || resource.user == self
    when Comment then role_admin? || role_moderator? || resource.user == self
    else role_admin?
    end
  end
end
```

## Controller Authorization Pattern

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :ensure_can_edit_post, only: [:edit, :update, :destroy]

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def ensure_can_edit_post
    unless current_user.can_edit?(@post)
      Rails.logger.warn "Unauthorized edit attempt: user=#{current_user.id} post=#{@post.id}"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Not authorized to edit this post" }
        format.json { head :forbidden }
      end
    end
  end
end
```

## Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src :self, :https, -> { "'nonce-#{content_security_policy_nonce}'" }
  policy.style_src :self
  policy.img_src :self, :data, "https:"
  policy.font_src :self
  policy.connect_src :self
  policy.frame_ancestors :none
end

Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
```

## Rate Limiting

```ruby
class ApplicationController < ActionController::Base
  rate_limit to: 1000, within: 1.hour, by: -> { current_user&.id || request.ip }
end

class SessionsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: :create,
             with: -> { render json: { error: "Rate limit exceeded" }, status: :too_many_requests }
end
```

## API Token Authentication

```ruby
class User < ApplicationRecord
  has_secure_token :auth_token

  def regenerate_auth_token!
    regenerate_auth_token
    save!
  end
end

class ApiController < ApplicationController
  before_action :authenticate_api_user

  private

  def authenticate_api_user
    token = request.headers['Authorization']&.remove('Bearer ')
    @current_user = User.find_by(auth_token: token)
    head :unauthorized unless @current_user
  end
end
```

## File Upload Validation

```ruby
class Document < ApplicationRecord
  has_one_attached :file
  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    unless file.blob.byte_size <= 10.megabyte
      errors.add(:file, "is too big (should be at most 10MB)")
    end

    acceptable_types = %w[image/jpeg image/png application/pdf]
    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, "must be a JPEG, PNG, or PDF")
    end
  end
end
```

## Structured Security Logging

```ruby
class SecurityLogger
  def self.log_authentication_failure(email, ip_address)
    Rails.logger.warn({
      event: "authentication_failure",
      email: email,
      ip_address: ip_address,
      timestamp: Time.current
    }.to_json)
  end

  def self.log_authorization_failure(user, resource, action)
    Rails.logger.warn({
      event: "authorization_failure",
      user_id: user.id,
      resource: resource.class.name,
      resource_id: resource.id,
      action: action,
      timestamp: Time.current
    }.to_json)
  end
end
```
