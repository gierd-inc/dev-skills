# Rails Active Storage

## Attachment Types

- Use `has_one_attached :avatar` for single file fields
- Use `has_many_attached :documents` for collections
- Prefer descriptive names (e.g., `profile_picture` over `image`)

## Validations

- Active Storage does not include file validations out of the box
- Validate presence, content type, and file size manually using custom validation methods
- Check `avatar.attached?` for presence and `avatar.blob.content_type` for format

## Image Processing

- Use `variant(resize_to_limit: [...])` for resizing
- Guard with `representable?` before calling `.variant` on non-image blobs
- Always check `attached?` before rendering

## Direct Uploads

- Use `form.file_field :avatar, direct_upload: true` for direct-to-storage uploads
- Configure CORS headers and JS uploader if using S3 or CDN
- Associate uploads after submit for security and data integrity

## Storage Backends

- Define backends in `config/storage.yml` (built-in services: `Disk`, `S3`, `GCS`, `Mirror`)
- Set service per environment in `config/environments/*.rb`: `config.active_storage.service = :local`
- Run `rails active_storage:install` to add required tables
- Note: the Azure backend is deprecated as of Rails 8.0

## Examples

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
