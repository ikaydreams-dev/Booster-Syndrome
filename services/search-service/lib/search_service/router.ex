defmodule SearchService.Router do
  use Plug.Router

  plug(CORSPlug)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "healthy", service: "search-service"}))
  end

  post "/api/v1/search" do
    {:ok, body, conn} = read_body(conn)
    params = Jason.decode!(body)

    results = SearchService.Index.search(params["query"])

    send_resp(conn, 200, Jason.encode!(%{results: results}))
  end

  post "/api/v1/index" do
    {:ok, body, conn} = read_body(conn)
    params = Jason.decode!(body)

    SearchService.Index.index_document(params)

    send_resp(conn, 201, Jason.encode!(%{message: "Document indexed"}))
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end
end
