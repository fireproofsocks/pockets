defmodule Pockets.DetsTable do
  @moduledoc """
  A struct defining information about an Erlang `:dets` disk-based table,
  adapted from [:dets.info/1](https://erlang.org/doc/man/dets.html#info-1).

  Note that the `filename` is represented by `Pockets` as a binary (not a charlist, like `:dets`).
  `:dets` refers to the table as a path that has been converted to an atom, e.g. `:"/tmp/my_table.dets"`
  """

  # DETS:
  # iex> :dets.info(:"/tmp/ex.dets")
  # [type: :set, keypos: 1, size: 0, file_size: 5432, filename: '/tmp/ex.dets']
  @enforce_keys [:name, :type, :table_ref]
  defstruct [
    # custom
    # <-- process name (set here so the DETS struct will also have a :name like the ETS struct)
    :name,
    # atom version of the filename, req'd by dets
    :table_ref,
    # Shared
    :type,
    :size,
    :keypos,
    # Specific to DETS
    :file_size,
    # (as binary)
    :filename
  ]

  def from_list(info, table_name) do
    map = Enum.into(info, %{})

    struct(
      __MODULE__,
      map
      |> Map.put(:table_ref, List.to_atom(map[:filename]))
      |> Map.put(:name, table_name)
      |> Map.put(:filename, to_string(map[:filename]))
    )
  end
end
