defmodule Pockets.Table do
  @moduledoc """
  A simple struct that we store for each `Pockets` table so that we can nicely map what _you_
  use to refer to your `Pockets` table and what the behind-the-scenes library uses to refer to the
  table.

  - `alias`: what you (the developer) uses to refer to your `Pocket` tables.
  - `tid`: the table identifier: i.e. what the `library` uses to identify the table.
  - `library`: denotes either `:ets` or `:dets`
  - `type` : the type of storage. `:bag` | `:duplicate_bag` | `:set`
  """

  @type t :: %__MODULE__{
          alias: atom,
          tid: Pockets.alias(),
          library: :ets | :dets,
          type: atom,
          opts: keyword
        }

  @enforce_keys [:alias, :tid, :library, :type]
  defstruct [
    :alias,
    :tid,
    :library,
    :type,
    :opts
  ]
end
