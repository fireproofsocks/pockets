defmodule Pockets.EtsInfo do
  @moduledoc """
  A struct defining information about an Erlang `:ets` in-memory table,
  adapted from [:ets.info/1](https://erlang.org/doc/man/ets.html#info-1)

  This struct is one of the possible values returned from `Pockets.info/1`.
  """
  @type t :: %__MODULE__{
          name: atom,
          type: :bag | :duplicate_bag | :set,
          size: integer,
          keypos: integer,
          id: Pockets.alias(),
          decentralized_counters: any,
          read_concurrency: boolean,
          write_concurrency: boolean,
          compressed: any,
          memory: any,
          owner: any,
          heir: any,
          node: any,
          named_table: boolean,
          protection: any
        }

  defstruct [
    :name,
    :type,
    :size,
    :keypos,
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

  def new(info), do: struct(__MODULE__, info)
end
