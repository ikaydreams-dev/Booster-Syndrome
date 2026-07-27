defmodule Booster.PipelineTest do
  use ExUnit.Case
  alias Booster.Pipeline

  test "creates new pipeline" do
    pipeline = Pipeline.new()
    assert %Pipeline{steps: []} = pipeline
  end

  test "adds step to pipeline" do
    pipeline = Pipeline.new()
    step = fn x -> {:ok, x + 1} end
    
    pipeline = Pipeline.add_step(pipeline, step)
    assert length(pipeline.steps) == 1
  end

  test "runs pipeline with single step" do
    pipeline = Pipeline.new()
    |> Pipeline.add_step(fn x -> {:ok, x * 2} end)
    
    result = Pipeline.run(pipeline, 5)
    assert result == {:ok, 10}
  end

  test "runs pipeline with multiple steps" do
    pipeline = Pipeline.new()
    |> Pipeline.add_step(fn x -> {:ok, x + 1} end)
    |> Pipeline.add_step(fn x -> {:ok, x * 2} end)
    |> Pipeline.add_step(fn x -> {:ok, x - 3} end)
    
    result = Pipeline.run(pipeline, 5)
    assert result == {:ok, 9}
  end

  test "stops pipeline on error" do
    pipeline = Pipeline.new()
    |> Pipeline.add_step(fn x -> {:ok, x + 1} end)
    |> Pipeline.add_step(fn _x -> {:error, "Something went wrong"} end)
    |> Pipeline.add_step(fn x -> {:ok, x * 2} end)
    
    result = Pipeline.run(pipeline, 5)
    assert result == {:error, "Something went wrong"}
  end

  test "map transformation" do
    transform = Pipeline.map(fn x -> x * 2 end)
    result = transform.([1, 2, 3])
    assert result == {:ok, [2, 4, 6]}
  end

  test "filter transformation" do
    transform = Pipeline.filter(fn x -> x > 2 end)
    result = transform.([1, 2, 3, 4, 5])
    assert result == {:ok, [3, 4, 5]}
  end
end
