defmodule SearchService.MixProject do
  use Mix.Project

  def project do
    [
      app: :search_service,
      version: "1.0.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SearchService.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2"},
      {:elastix, "~> 0.10.0"},
      {:cors_plug, "~> 3.0"}
    ]
  end
end
