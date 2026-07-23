defmodule Booster.PatternMatching do
  @moduledoc """
  Pattern matching and regex utilities for Booster
  """

  def validate_email(email) do
    regex = ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
    Regex.match?(regex, email)
  end

  def validate_url(url) do
    regex = ~r/^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)$/
    Regex.match?(regex, url)
  end

  def validate_phone(phone) do
    regex = ~r/^\+?[1-9]\d{1,14}$/
    cleaned = String.replace(phone, ~r/[\s-]/, "")
    Regex.match?(regex, cleaned)
  end

  def extract_mentions(text) do
    regex = ~r/@(\w+)/
    Regex.scan(regex, text)
    |> Enum.map(fn [_, username] -> username end)
  end

  def extract_hashtags(text) do
    regex = ~r/#(\w+)/
    Regex.scan(regex, text)
    |> Enum.map(fn [_, tag] -> tag end)
  end

  def extract_urls(text) do
    regex = ~r/https?:\/\/[^\s]+/
    Regex.scan(regex, text)
    |> Enum.map(fn [url] -> url end)
  end

  def sanitize_html(html) do
    html
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
  end

  def slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  def truncate(text, length) do
    if String.length(text) <= length do
      text
    else
      String.slice(text, 0, length) <> "..."
    end
  end

  def mask_email(email) do
    case String.split(email, "@") do
      [local, domain] ->
        masked_local = String.slice(local, 0, 2) <> String.duplicate("*", String.length(local) - 2)
        "#{masked_local}@#{domain}"
      _ ->
        email
    end
  end
end
