defmodule Pockets.Registry do
  # Simple map to keep state: it stores which pocket tables have been opened and what type they are
  @moduledoc false
  use GenServer
  require Logger

  def start_link(_args \\ %{}), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Looks up the info for the given `table_id`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(table_id) do
    GenServer.call(__MODULE__, {:lookup, table_id})
  end

  @doc """
  Registers the `info` for the given `table_id`.
  """
  def register(table_id, info) do
    GenServer.call(__MODULE__, {:register, table_id, info})
  end


  def stop(), do: GenServer.cast(__MODULE__, :stop)



  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:lookup, table_id}, _from, state) do
    {:reply, Map.get(state, table_id), state}
  end

  @impl true
  def handle_call({:register, table_id, info}, _from, state) do
    {:reply, :ok, Map.put(state, table_id, info)}
  end

  @impl GenServer
  def handle_cast(:stop, state), do: {:stop, :normal, state}

  @impl GenServer
  def terminate(reason, _state) do
    Logger.info("#{__MODULE__} stopped : #{inspect(reason)}")
    :ok
  end
end
