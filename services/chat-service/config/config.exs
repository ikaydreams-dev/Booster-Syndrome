import Config

config :chat_service,
  port: 8007,
  pubsub_name: ChatService.PubSub

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
