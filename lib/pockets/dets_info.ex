defmodule Pockets.DetsInfo do
  @moduledoc """
  A struct defining information about an Erlang `:dets` disk-based table,
  adapted from [:dets.info/1](https://erlang.org/doc/man/dets.html#info-1).

  Note that the `filename` is represented by `Pockets` as a binary (not a charlist, like `:dets`).
  `:dets` refers to the table as a path that has been converted to an atom, e.g. `:"/tmp/my_table.dets"`

  - `table_id` is the table identifier used in the Pockets calls.
  - `table_ref` is the table identifier used with :dets commands
  """

  # DETS:
  # iex> :dets.info(:"/tmp/ex.dets")
  # [type: :set, keypos: 1, size: 0, file_size: 5432, filename: '/tmp/ex.dets']
  #  @enforce_keys [:table_id, :type, :table_ref, :library]
  defstruct [
    :type,
    :keypos,
    :size,
    :file_size,
    :filename
  ]

  def new(info), do: struct(__MODULE__, info)
  #    map = Enum.into(info, %{})
  #
  #    struct(
  #      __MODULE__,
  #      map
  #      |> Map.put(:table_ref, List.to_atom(map[:filename]))
  #      |> Map.put(:table_id, table_id)
  #      |> Map.put(:filename, to_string(map[:filename]))
  #      |> Map.put(:library, :dets)
  #    )
  #  end
end
