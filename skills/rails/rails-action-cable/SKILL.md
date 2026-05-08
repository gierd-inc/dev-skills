---
name: rails-action-cable
description: use when writing Action Cable channels, WebSocket subscriptions, broadcasts
---

# Rails Action Cable

## Architecture

- Use one channel per resource domain (e.g., `ChatChannel`, `RoomChannel`)
- Channels manage WebSocket subscriptions; streams represent broadcast sources
- Use multiple `stream_for` or `stream_from` calls within one channel when needed
- Use Solid Cable in production — the Rails 8 default DB-backed pub/sub adapter (no Redis required; ~1 day message retention)
- Never use dynamic string interpolation in stream names without explicit authorization

## Subscription Lifecycle

- Always define both `subscribed` and `unsubscribed` methods
- Call `stream_for resource` or `stream_from "stream_name"` inside `subscribed`
- Call `stop_all_streams` in `unsubscribed` to clean up
- Set `current_user` only in `ApplicationCable::Connection#connect`, not in channels

## Security

- Do not rely on `current_user` alone — always explicitly authorize resource access
- Validate that the current user can access the resource before calling `stream_for`
- Use `reject` (in channels) or `reject_unauthorized_connection` (in connection) to halt unauthorized access

## Turbo Integration

- Use `turbo_stream_from @resource` in views to subscribe to model broadcasts
- Use `broadcasts_to` on the model for automatic Turbo broadcasting
- Use `Turbo::StreamsChannel.broadcast_replace_to` for manual stream pushes when no model callback is available

See `references/examples.md` for code samples.
