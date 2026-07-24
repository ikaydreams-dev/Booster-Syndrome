defmodule Booster.Pipeline do
  @moduledoc """
  Data processing pipeline with composable transformations
  """

  defstruct steps: []

  def new do
    %__MODULE__{steps: []}
  end

  def add_step(pipeline, step) when is_function(step, 1) do
    %{pipeline | steps: pipeline.steps ++ [step]}
  end

  def run(pipeline, input) do
    Enum.reduce_while(pipeline.steps, {:ok, input}, fn step, {:ok, value} ->
      case step.(value) do
        {:ok, new_value} -> {:cont, {:ok, new_value}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  # Built-in transformations

  def map(func) do
    fn data when is_list(data) ->
      {:ok, Enum.map(data, func)}
    end
  end

  def filter(predicate) do
    fn data when is_list(data) ->
      {:ok, Enum.filter(data, predicate)}
    end
  end

  def validate(validator) do
    fn data ->
      case validator.(data) do
        :ok -> {:ok, data}
        {:error, _} = error -> error
      end
    end
  end

  def transform(transformer) do
    fn data ->
      {:ok, transformer.(data)}
    end
  end

  def batch(size) do
    fn data when is_list(data) ->
      {:ok, Enum.chunk_every(data, size)}
    end
  end
end
