defmodule Counter do
  use GenServer

  def start_link(initial_value \\ 0) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def increment do
    GenServer.call(__MODULE__, :increment)
  end

  def decrement do
    GenServer.call(__MODULE__, :decrement)
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  @impl true
  def init(initial_value) do
    {:ok, initial_value}
  end

  @impl true
  def handle_call(:increment, _from, state) do
    new_state = state + 1
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:decrement, _from, state) do
    new_state = state - 1
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, 0}
  end
end

defmodule KeyValueStore do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def put(pid, key, value) do
    GenServer.call(pid, {:put, key, value})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def delete(pid, key) do
    GenServer.call(pid, {:delete, key})
  end

  def keys(pid) do
    GenServer.call(pid, :keys)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    new_state = Map.put(state, key, value)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    new_state = Map.delete(state, key)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:keys, _from, state) do
    {:reply, Map.keys(state), state}
  end
end

defmodule TaskQueue do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{queue: :queue.new(), workers: []}, opts)
  end

  def enqueue(pid, task) do
    GenServer.cast(pid, {:enqueue, task})
  end

  def dequeue(pid) do
    GenServer.call(pid, :dequeue)
  end

  def size(pid) do
    GenServer.call(pid, :size)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:enqueue, task}, %{queue: queue} = state) do
    new_queue = :queue.in(task, queue)
    {:noreply, %{state | queue: new_queue}}
  end

  @impl true
  def handle_call(:dequeue, _from, %{queue: queue} = state) do
    case :queue.out(queue) do
      {{:value, task}, new_queue} ->
        {:reply, {:ok, task}, %{state | queue: new_queue}}
      {:empty, _} ->
        {:reply, {:error, :empty}, state}
    end
  end

  @impl true
  def handle_call(:size, _from, %{queue: queue} = state) do
    {:reply, :queue.len(queue), state}
  end
end

defmodule PubSub do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{subscribers: %{}}, opts)
  end

  def subscribe(pid, topic, subscriber_pid) do
    GenServer.call(pid, {:subscribe, topic, subscriber_pid})
  end

  def unsubscribe(pid, topic, subscriber_pid) do
    GenServer.call(pid, {:unsubscribe, topic, subscriber_pid})
  end

  def publish(pid, topic, message) do
    GenServer.cast(pid, {:publish, topic, message})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:subscribe, topic, subscriber_pid}, _from, %{subscribers: subs} = state) do
    topic_subs = Map.get(subs, topic, [])
    new_subs = Map.put(subs, topic, [subscriber_pid | topic_subs])
    {:reply, :ok, %{state | subscribers: new_subs}}
  end

  @impl true
  def handle_call({:unsubscribe, topic, subscriber_pid}, _from, %{subscribers: subs} = state) do
    topic_subs = Map.get(subs, topic, [])
    new_topic_subs = List.delete(topic_subs, subscriber_pid)
    new_subs = Map.put(subs, topic, new_topic_subs)
    {:reply, :ok, %{state | subscribers: new_subs}}
  end

  @impl true
  def handle_cast({:publish, topic, message}, %{subscribers: subs} = state) do
    topic_subs = Map.get(subs, topic, [])
    Enum.each(topic_subs, fn pid ->
      send(pid, {:message, topic, message})
    end)
    {:noreply, state}
  end
end

defmodule RateLimiter do
  use GenServer

  def start_link(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    window = Keyword.get(opts, :window, 60)
    GenServer.start_link(__MODULE__, %{limit: limit, window: window, requests: []}, opts)
  end

  def allow?(pid, key) do
    GenServer.call(pid, {:allow?, key})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:allow?, key}, _from, %{limit: limit, window: window, requests: reqs} = state) do
    now = :os.system_time(:second)
    cutoff = now - window

    cleaned_requests = Enum.filter(reqs, fn {_, time} -> time > cutoff end)
    key_requests = Enum.filter(cleaned_requests, fn {k, _} -> k == key end)

    if length(key_requests) < limit do
      new_requests = [{key, now} | cleaned_requests]
      {:reply, true, %{state | requests: new_requests}}
    else
      {:reply, false, %{state | requests: cleaned_requests}}
    end
  end
end
