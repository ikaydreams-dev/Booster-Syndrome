defmodule ChatService.Config do
  @moduledoc """
  Chat service configuration
  """

  def redis_url do
    System.get_env("REDIS_URL", "redis://localhost:6379")
  end

  def port do
    String.to_integer(System.get_env("PORT", "4000"))
  end

  def max_message_length do
    String.to_integer(System.get_env("MAX_MESSAGE_LENGTH", "5000"))
  end

  def message_retention_days do
    String.to_integer(System.get_env("MESSAGE_RETENTION_DAYS", "90"))
  end

  def max_room_participants do
    String.to_integer(System.get_env("MAX_ROOM_PARTICIPANTS", "100"))
  end

  def websocket_timeout do
    String.to_integer(System.get_env("WEBSOCKET_TIMEOUT_MS", "60000"))
  end
end
