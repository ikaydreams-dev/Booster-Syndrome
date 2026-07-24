defmodule Booster.GenServerWorker do
  use GenServer

  # Client API

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def update_state(key, value) do
    GenServer.cast(__MODULE__, {:update, key, value})
  end

  def process_job(job) do
    GenServer.call(__MODULE__, {:process_job, job})
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:process_job, job}, _from, state) do
    result = do_process_job(job)
    new_state = Map.update(state, :jobs_processed, 1, &(&1 + 1))
    {:reply, result, new_state}
  end

  @impl true
  def handle_cast({:update, key, value}, state) do
    new_state = Map.put(state, key, value)
    {:noreply, new_state}
  end

  # Private Functions

  defp do_process_job(%{type: "email", data: data}) do
    # Process email job
    {:ok, "Email sent to #{data["to"]}"}
  end

  defp do_process_job(%{type: "notification", data: data}) do
    # Process notification job
    {:ok, "Notification sent to user #{data["user_id"]}"}
  end

  defp do_process_job(_job) do
    {:error, "Unknown job type"}
  end
end
