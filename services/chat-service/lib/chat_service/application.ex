defmodule ChatService.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: ChatService.PubSub},
      {Plug.Cowboy, scheme: :http, plug: ChatService.Router, options: [port: 8007]}
    ]

    opts = [strategy: :one_for_one, name: ChatService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
