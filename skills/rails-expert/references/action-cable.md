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

## Examples

## Connection Identification

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      User.find_by(id: cookies.encrypted[:user_id]) || reject_unauthorized_connection
    end
  end
end
```

## Basic Channel with Stream

```ruby
# app/channels/room_channel.rb
class RoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:id])
    stream_for room
  end

  def unsubscribed
    stop_all_streams
  end
end
```

## Channel with Authorization

```ruby
# app/channels/room_channel.rb
class RoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:id])
    reject unless current_user.can_access?(room)
    stream_for room
  end

  def unsubscribed
    stop_all_streams
  end
end
```

## Multi-Stream Channel with Incoming Message Handling

```ruby
class RoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:id])
    reject unless current_user.can_access?(room)

    stream_for room
    stream_from "room_#{room.id}_presence"
    stream_from "user_#{current_user.id}_notifications"
  end

  def receive(data)
    case data["type"]
    when "typing"
      broadcast_typing_status(data["typing"])
    end
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def broadcast_typing_status(typing)
    ActionCable.server.broadcast(
      "room_#{params[:id]}_presence",
      { user: current_user.name, typing: typing, timestamp: Time.current }
    )
  end
end
```

## Turbo Stream View Subscription

```erb
<%# app/views/rooms/show.html.erb %>
<%= turbo_stream_from @room %>
```

## Manual Turbo Stream Broadcast

```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  @room,
  target: "messages",
  partial: "messages/list",
  locals: { messages: @room.messages }
)
```
