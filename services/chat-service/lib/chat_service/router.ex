defmodule ChatService.Router do
  use Plug.Router

  plug(CORSPlug)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "healthy", service: "chat-service"}))
  end

  post "/api/v1/messages" do
    {:ok, body, conn} = read_body(conn)
    params = Jason.decode!(body)

    ChatService.MessageHandler.broadcast_message(params)

    send_resp(conn, 201, Jason.encode!(%{message: "Message sent"}))
  end

  get "/api/v1/rooms/:room_id/messages" do
    room_id = conn.params["room_id"]
    messages = ChatService.MessageHandler.get_room_messages(room_id)

    send_resp(conn, 200, Jason.encode!(%{messages: messages}))
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end
end
