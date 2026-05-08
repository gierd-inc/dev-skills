---
name: rails-action-text
description: use when working with Action Text rich content, trix editor, has_rich_text
---

# Rails Action Text

## Rich Text Usage

- Use `has_rich_text :field` for storing long-form or formatted content
- Avoid storing raw HTML in plain string columns
- Use `.to_plain_text` or `.to_trix_html` when rendering or indexing rich content
- Validate presence on the virtual attribute: `validates :body, presence: true`

## Embeds vs Attachments

- **Attachments** are files/media associated with the model
- **Embeds** are inline references within the rich text content
- Use `record.body.attachables` to retrieve embedded models
- Use `ActionText::Attachable.from_attachable(record)` to generate embeds
- Don't manually serialize `attachable_sgid` unless you fully control the context

## Security & Sanitization

- Rails sanitizes content by default; additional measures may be needed for untrusted input
- Be cautious with copy-paste from Google Docs, Word, or third-party sites
- Customize sanitization using `sanitize(content.to_html, tags: [...])`
- Audit for embedded scripts, base64 images, or style blocks

See `references/examples.md` for code samples.
