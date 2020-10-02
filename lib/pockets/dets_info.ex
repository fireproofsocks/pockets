defmodule Pockets.DetsInfo do
  @moduledoc """
  A struct defining information about an Erlang `:dets` disk-based table,
  adapted from [:dets.info/1](https://erlang.org/doc/man/dets.html#info-1).

  This struct is one of the possible values returned from `Pockets.info/1`.

  Note that `:dets` refers to a table's filename as a path that has been converted to an atom,
  e.g. `:"/tmp/my_table.dets"`
  """

  @type t :: %__MODULE__{
          type: :bag | :duplicate_bag | :set,
          keypos: integer,
          size: integer,
          file_size: integer,
          filename: atom
        }

  defstruct [
    :type,
    :keypos,
    :size,
    :file_size,
    :filename
  ]

  def new(info), do: struct(__MODULE__, info)
end
