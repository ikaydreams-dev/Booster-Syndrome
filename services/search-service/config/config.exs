import Config

config :search_service,
  port: 8006,
  elasticsearch_url: "http://localhost:9200",
  index_name: "booster_index"

import_config "#{config_env()}.exs"
