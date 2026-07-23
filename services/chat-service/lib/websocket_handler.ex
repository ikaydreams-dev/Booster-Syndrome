defmodule ChatService.WebSocketHandler do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    state = %{
      user_id: nil,
      room_id: nil,
      registry_key: nil
    }

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, %{"type" => "join", "room_id" => room_id, "user_id" => user_id}} ->
        handle_join(room_id, user_id, state)

      {:ok, %{"type" => "message", "content" => content}} ->
        handle_message(content, state)

      {:ok, %{"type" => "leave"}} ->
        handle_leave(state)

      _ ->
        {:reply, {:text, Jason.encode!(%{error: "Invalid message"})}, state}
    end
  end

  def websocket_info({:broadcast, message}, state) do
    {:reply, {:text, Jason.encode!(message)}, state}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  defp handle_join(room_id, user_id, state) do
    registry_key = {:room, room_id}

    Registry.register(ChatService.Registry, registry_key, [])

    Phoenix.PubSub.subscribe(ChatService.PubSub, "room:#{room_id}")

    new_state = %{state | user_id: user_id, room_id: room_id, registry_key: registry_key}

    broadcast_to_room(room_id, %{
      type: "user_joined",
      user_id: user_id
    })

    {:reply, {:text, Jason.encode!(%{type: "joined", room_id: room_id})}, new_state}
  end

  defp handle_message(content, %{room_id: nil} = state) do
    {:reply, {:text, Jason.encode!(%{error: "Not in a room"})}, state}
  end

  defp handle_message(content, %{room_id: room_id, user_id: user_id} = state) do
    message = %{
      type: "message",
      user_id: user_id,
      content: content,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    broadcast_to_room(room_id, message)

    {:ok, state}
  end

  defp handle_leave(%{room_id: room_id, user_id: user_id} = state) do
    Phoenix.PubSub.unsubscribe(ChatService.PubSub, "room:#{room_id}")

    broadcast_to_room(room_id, %{
      type: "user_left",
      user_id: user_id
    })

    {:ok, %{state | room_id: nil, user_id: nil}}
  end

  defp broadcast_to_room(room_id, message) do
    Phoenix.PubSub.broadcast(ChatService.PubSub, "room:#{room_id}", {:broadcast, message})
  end
end
