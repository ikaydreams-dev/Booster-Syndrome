defmodule SearchService.Indexer do
  @moduledoc """
  Elasticsearch indexer for search functionality
  """

  require Logger

  def index_user(user) do
    document = %{
      id: user.id,
      username: user.username,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      bio: user.bio,
      created_at: user.created_at
    }

    case HTTPoison.post(
      "#{elasticsearch_url()}/users/_doc/#{user.id}",
      Jason.encode!(document),
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: status}} when status in [200, 201] ->
        Logger.info("Indexed user: #{user.id}")
        {:ok, document}

      {:error, error} ->
        Logger.error("Failed to index user: #{inspect(error)}")
        {:error, error}
    end
  end

  def search_users(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    search_query = %{
      query: %{
        multi_match: %{
          query: query,
          fields: ["username^3", "first_name^2", "last_name^2", "bio"]
        }
      },
      size: limit
    }

    case HTTPoison.post(
      "#{elasticsearch_url()}/users/_search",
      Jason.encode!(search_query),
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: 200, body: body}} ->
        results = Jason.decode!(body)
        hits = get_in(results, ["hits", "hits"]) || []

        users = Enum.map(hits, fn hit ->
          hit["_source"]
        end)

        {:ok, users}

      {:error, error} ->
        {:error, error}
    end
  end

  def delete_user(user_id) do
    HTTPoison.delete("#{elasticsearch_url()}/users/_doc/#{user_id}")
  end

  defp elasticsearch_url do
    SearchService.Config.elasticsearch_url()
  end
end
