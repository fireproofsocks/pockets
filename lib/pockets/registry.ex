defmodule Pockets.Registry do
  # Simple map to keep state: it stores which pocket tables have been opened and what type they are
  @moduledoc false
  use GenServer
  import Pockets, only: [is_alias: 1]
  alias Pockets.Table
  require Logger

  def start_link(_args \\ %{}), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Checks to see if the given table exists.
  """
  def exists?(table_alias) when is_alias(table_alias) do
    GenServer.call(__MODULE__, {:exists?, table_alias})
  end

  @doc """
  Flushes the registry
  """
  def flush do
    GenServer.call(__MODULE__, {:flush})
  end

  @doc """
  Gets the entire registry.
  """
  def list, do: GenServer.call(__MODULE__, {:list})

  @doc """
  Looks up the info for the given `table_alias`.
  """
  def lookup(table_alias) when is_alias(table_alias) do
    GenServer.call(__MODULE__, {:lookup, table_alias})
  end

  @doc """
  Registers the `info` for the given `table_alias`.
  """
  @spec register(Pockets.alias(), Table.t()) :: {:ok, atom}
  def register(table_alias, %Table{} = info) when is_alias(table_alias) do
    GenServer.call(__MODULE__, {:register, table_alias, info})
  end

  @doc """
  Unregisters the given `table_alias`: this should be done when a table is deleted.
  """
  def unregister(table_alias) when is_alias(table_alias) do
    GenServer.call(__MODULE__, {:unregister, table_alias})
  end

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:exists?, table_alias}, _from, state) do
    {:reply, Map.has_key?(state, table_alias), state}
  end

  @impl true
  def handle_call({:flush}, _from, _state) do
    {:reply, :ok, %{}}
  end

  @impl true
  def handle_call({:list}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:lookup, table_alias}, _from, state) do
    {:reply, Map.get(state, table_alias), state}
  end

  @impl true
  def handle_call({:register, table_alias, info}, _from, state) do
    {:reply, {:ok, table_alias}, Map.put(state, table_alias, info)}
  end

  @impl true
  def handle_call({:unregister, table_alias}, _from, state) do
    {:reply, :ok, Map.delete(state, table_alias)}
  end
end
