defmodule SearchService.Index do
  @elasticsearch_url "http://localhost:9200"
  @index_name "booster_index"

  def search(query) do
    body = %{
      query: %{
        multi_match: %{
          query: query,
          fields: ["title^2", "content", "tags"]
        }
      }
    }

    case HTTPoison.post("#{@elasticsearch_url}/#{@index_name}/_search", Jason.encode!(body), [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        response = Jason.decode!(response_body)
        get_in(response, ["hits", "hits"]) |> Enum.map(&Map.get(&1, "_source"))

      {:error, _} ->
        []
    end
  end

  def index_document(document) do
    id = Map.get(document, "id", UUID.uuid4())

    HTTPoison.put(
      "#{@elasticsearch_url}/#{@index_name}/_doc/#{id}",
      Jason.encode!(document),
      [{"Content-Type", "application/json"}]
    )
  end

  def create_index do
    body = %{
      mappings: %{
        properties: %{
          title: %{type: "text"},
          content: %{type: "text"},
          tags: %{type: "keyword"},
          created_at: %{type: "date"}
        }
      }
    }

    HTTPoison.put(
      "#{@elasticsearch_url}/#{@index_name}",
      Jason.encode!(body),
      [{"Content-Type", "application/json"}]
    )
  end
end
