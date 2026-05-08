# Rails Models — Code Samples

## Advanced Model Example

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Publishable

  # Rails Edge data normalization
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.strip.titleize }

  encrypts :ssn
  has_secure_password
  has_secure_token :auth_token
  has_rich_text :bio
  has_many_attached :documents

  enum :role, { user: 0, admin: 1 }, suffix: true, scopes: false

  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, on: :create
  validates :ssn, format: { with: /\A\d{3}-\d{2}-\d{4}\z/ }, allow_blank: true

  broadcasts_refreshes  # Rails Edge real-time updates

  scope :verified, -> { where(verified: true) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :send_welcome_email

  def display_name
    name.presence || email.split("@").first
  end

  def can_administer?(resource)
    admin? && (resource.user == self || resource.public?)
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

## Associations with Default and Extension

```ruby
class Post < ApplicationRecord
  belongs_to :author, class_name: "User", default: -> { Current.user }
end

has_many :memberships, dependent: :delete_all do
  def grant_to(users)
    room = proxy_association.owner
    Membership.insert_all(Array(users).collect { |user| { room_id: room.id, user_id: user.id } })
  end
end
```

## Validations

```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 13 }

  validate :email_domain_allowed

  private

  def email_domain_allowed
    return unless email.present?
    domain = email.split('@').last
    errors.add(:email, "domain not allowed") unless allowed_domains.include?(domain)
  end
end
```

## Scopes and Class Methods

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  scope :published, -> { where(status: "published") }
  scope :recent, -> { order(created_at: :desc) }

  def self.recent_published
    published.recent.limit(10)
  end
end

# Usage
Post.recent_published.includes(:user)
```

## Callbacks

```ruby
class User < ApplicationRecord
  after_commit :send_welcome_email, on: :create

  private

  def send_welcome_email
    WelcomeMailer.welcome_email(self).deliver_later
  end
end
```

## Turbo Broadcasts

```ruby
# Preferred (Rails Edge)
class Post < ApplicationRecord
  broadcasts_refreshes
end

# More granular control
broadcasts_to ->(post) { [post.user, :posts] }, inserts_by: :prepend

# Manual broadcast callbacks
class Message < ApplicationRecord
  belongs_to :room

  after_create_commit -> { broadcast_prepend_to room }
  after_update_commit -> { broadcast_replace_to room }
  after_destroy_commit -> { broadcast_remove_to room }
end
```

## Concern Example

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable, dependent: :destroy
    after_update_commit :log_changes
  end

  def audit_summary
    audit_logs.recent.limit(5).pluck(:action, :created_at)
  end

  private

  def log_changes
    return unless saved_changes.except("updated_at").any?

    AuditLog.create!(
      auditable: self,
      action: "updated",
      changes: saved_changes.except("updated_at"),
      user: Current.user
    )
  end
end
```

## Delegate and with_options

```ruby
class User < ApplicationRecord
  has_one :profile, dependent: :destroy

  delegate :bio, :website, :avatar, to: :profile, prefix: false, allow_nil: true
  delegate :full_name, to: :profile, prefix: false, allow_nil: true

  with_options presence: true do
    validates :name
    validates :email
  end

  def latest_post_title
    posts.published.first&.title
  end
end
```

## Business Logic Domain Model

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :published_posts, -> { published }, class_name: "Post"

  after_create_commit :send_welcome_email
  before_save :normalize_email

  def can_publish?
    posts.count >= 5 && account_in_good_standing?
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    name.presence || email.presence || "Anonymous User"
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def account_in_good_standing?
    !suspended? && email_verified?
  end
end
```

## Timestamps in Migrations

```ruby
t.create_table :posts do |t|
  t.string :title
  t.timestamps null: false
end
```
