defmodule ChatService.MessageHandler do
  alias Phoenix.PubSub

  @messages_store :ets.new(:messages, [:set, :public, :named_table])

  def broadcast_message(%{"room_id" => room_id, "user_id" => user_id, "content" => content}) do
    message = %{
      id: UUID.uuid4(),
      room_id: room_id,
      user_id: user_id,
      content: content,
      timestamp: DateTime.utc_now()
    }

    store_message(message)

    PubSub.broadcast(ChatService.PubSub, "room:#{room_id}", {:new_message, message})

    {:ok, message}
  end

  def get_room_messages(room_id) do
    case :ets.lookup(@messages_store, room_id) do
      [{^room_id, messages}] -> messages
      [] -> []
    end
  end

  defp store_message(message) do
    room_id = message.room_id
    existing_messages = get_room_messages(room_id)
    updated_messages = [message | existing_messages] |> Enum.take(100)

    :ets.insert(@messages_store, {room_id, updated_messages})
  end
end
