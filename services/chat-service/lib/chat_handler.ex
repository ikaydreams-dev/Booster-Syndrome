defmodule ChatService.ChatHandler do
  @moduledoc """
  WebSocket handler for real-time chat
  """

  require Logger

  def handle_connect(%{"user_id" => user_id, "room_id" => room_id}) do
    Logger.info("User #{user_id} connecting to room #{room_id}")

    # Subscribe to room channel
    Phoenix.PubSub.subscribe(ChatService.PubSub, "room:#{room_id}")

    {:ok, %{user_id: user_id, room_id: room_id}}
  end

  def handle_message(%{"type" => "message", "content" => content}, state) do
    message = %{
      id: UUID.uuid4(),
      user_id: state.user_id,
      room_id: state.room_id,
      content: content,
      timestamp: DateTime.utc_now()
    }

    # Save message to database
    save_message(message)

    # Broadcast to room
    Phoenix.PubSub.broadcast(
      ChatService.PubSub,
      "room:#{state.room_id}",
      {:new_message, message}
    )

    {:reply, {:ok, message}, state}
  end

  def handle_message(%{"type" => "typing"}, state) do
    # Broadcast typing indicator
    Phoenix.PubSub.broadcast(
      ChatService.PubSub,
      "room:#{state.room_id}",
      {:user_typing, state.user_id}
    )

    {:noreply, state}
  end

  def handle_message(%{"type" => "read"}, state) do
    # Mark messages as read
    mark_messages_read(state.room_id, state.user_id)

    {:noreply, state}
  end

  def handle_disconnect(state) do
    Logger.info("User #{state.user_id} disconnecting from room #{state.room_id}")

    # Unsubscribe from room
    Phoenix.PubSub.unsubscribe(ChatService.PubSub, "room:#{state.room_id}")

    # Broadcast user left
    Phoenix.PubSub.broadcast(
      ChatService.PubSub,
      "room:#{state.room_id}",
      {:user_left, state.user_id}
    )

    :ok
  end

  def get_room_history(room_id, limit \\ 50) do
    # Fetch message history from database
    # Returns list of messages
    []
  end

  def get_room_participants(room_id) do
    # Get list of users in room
    []
  end

  defp save_message(message) do
    # Save to Redis or PostgreSQL
    Logger.debug("Saving message: #{inspect(message)}")
    :ok
  end

  defp mark_messages_read(room_id, user_id) do
    Logger.debug("Marking messages read for user #{user_id} in room #{room_id}")
    :ok
  end
end
