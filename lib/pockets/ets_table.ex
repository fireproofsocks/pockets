defmodule Pockets.EtsTable do
  @moduledoc """
  A struct defining information about an Erlang `:ets` in-memory table,
  adapted from [:ets.info/1](https://erlang.org/doc/man/ets.html#info-1)
  """

  # iex> :ets.info(:my_cache)
  # [
  #  id: #Reference<0.4127012117.1335492609.119067>,
  #  decentralized_counters: false,
  #  read_concurrency: true,
  #  write_concurrency: true,
  #  compressed: false,
  #  memory: 1335,
  #  owner: #PID<0.217.0>,
  #  heir: :none,
  #  name: :my_cache,
  #  size: 0,
  #  node: :nonode@nohost,
  #  named_table: true,
  #  type: :set,
  #  keypos: 1,
  #  protection: :public
  # ]
  @enforce_keys [:name, :type, :table_ref]
  defstruct [
    # custom
    # equal to table_name atom if :named_table, otherwise equal to id reference
    :table_ref,
    # Shared
    :name,
    :type,
    :size,
    :keypos,
    # Specific to ETS
    :id,
    :decentralized_counters,
    :read_concurrency,
    :write_concurrency,
    :compressed,
    :memory,
    :owner,
    :heir,
    :node,
    :named_table,
    :protection
  ]

  def from_list(info) do
    struct(
      __MODULE__,
      info
      |> Enum.into(%{})
      |> put_table_ref()
    )
  end

  defp put_table_ref(%{named_table: true} = map) do
    Map.put(map, :table_ref, map[:name])
  end

  defp put_table_ref(%{named_table: false} = map) do
    Map.put(map, :table_ref, map[:id])
  end
end
