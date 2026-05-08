---
name: rails-active-storage
description: use when working with Active Storage file attachments, variants, direct uploads
---

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

See `references/examples.md` for code samples.
