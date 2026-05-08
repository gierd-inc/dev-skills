---
name: rails-mailbox
description: use when writing Action Mailbox inbound email routing
---

# Rails Mailbox

## Routing Inbound Emails

- Define all routes in `app/mailboxes/application_mailbox.rb` using the `routing` DSL
- Prefer scoped routing via sub-addressing (`+tag`) to simplify mailbox matching
- Use descriptive class names matching route targets (e.g., `SupportMailbox`, `BillingMailbox`)
- Never create a mailbox class without a corresponding route

## Mailbox Class Structure

- Each mailbox inherits from `ApplicationMailbox`
- Implement the `receive` method to extract data from the inbound `mail` object
- Avoid side effects in parsing logic; keep extraction and persistence separate
- Always authenticate or verify the sender before performing sensitive actions

## Parsing and Sanitization

- Always sanitize incoming content before saving to models
- Use `mail.decoded` for body text, `mail.attachments` for files, `mail.multipart?` to branch on content type
- Use `ActionController::Base.helpers.sanitize` for HTML content
- Never store raw decoded body without sanitization

See `references/examples.md` for code samples.
