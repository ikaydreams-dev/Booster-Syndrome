defmodule SearchService.Config do
  @moduledoc """
  Configuration module for Search Service
  """

  def elasticsearch_url do
    System.get_env("ELASTICSEARCH_URL", "http://localhost:9200")
  end

  def elasticsearch_index_prefix do
    System.get_env("INDEX_PREFIX", "booster_")
  end

  def port do
    String.to_integer(System.get_env("PORT", "8002"))
  end

  def max_results do
    String.to_integer(System.get_env("MAX_SEARCH_RESULTS", "100"))
  end

  def search_timeout do
    String.to_integer(System.get_env("SEARCH_TIMEOUT_MS", "5000"))
  end
end
