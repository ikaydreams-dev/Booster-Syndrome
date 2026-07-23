defmodule SearchService do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: SearchService.Router, options: [port: 8006]}
    ]

    opts = [strategy: :one_for_one, name: SearchService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
