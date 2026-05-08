# Active Storage Examples

## Model with Attachments and Validations

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :documents

  validate :avatar_presence
  validate :avatar_format

  def avatar_presence
    errors.add(:avatar, "must be attached") unless avatar.attached?
  end

  def avatar_format
    return unless avatar.attached?
    unless avatar.blob.content_type.in?(%w[image/png image/jpeg])
      errors.add(:avatar, "must be PNG or JPG")
    end
  end
end
```

## Form with Direct Upload

```erb
<%# app/views/users/_form.html.erb %>
<%= form_with model: @user do |form| %>
  <%= form.file_field :avatar, direct_upload: true %>
  <%= form.file_field :documents, multiple: true, direct_upload: true %>
<% end %>
```

## Image Rendering with Variant

```erb
<%# app/views/users/show.html.erb %>
<% if @user.avatar.attached? && @user.avatar.representable? %>
  <%= image_tag @user.avatar.variant(resize_to_limit: [300, 300]) %>
<% end %>
```

## Storage Configuration

```yaml
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: myapp-production
```

```ruby
# config/environments/production.rb
config.active_storage.service = :amazon
```
