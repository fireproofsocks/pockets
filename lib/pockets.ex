defmodule Pockets do
  @moduledoc """
  `Pockets` is a wrapper around Erlang [ETS](https://erlang.org/doc/man/ets.html)
  and [DETS](https://erlang.org/doc/man/dets.html), built-in options for memory- and disk-based term storage.

  This package offers a few conveniences.

  See also

  - [stash](https://github.com/whitfin/stash)
  - ["What is ETS in Elixir?"](https://culttt.com/2016/10/05/what-is-ets-in-elixir/)
  """

  use GenServer

  alias Pockets.{DetsTable, EtsTable}

  require Logger

  @table_types [:bag, :duplicate_bag, :set]

  @default_table_type :set
  @default_dets_opts [type: @default_table_type]

  # Here is an Elixir-friendly rendering of some (not all!) of the :ets.new/2 options.
  # These have to be converted into a list of mixed types before they are
  # passed to :ets.new/2
  @default_ets_opts [
    type: @default_table_type,
    access: :public,
    # if false, :ets.new/2 returns a reference not an atom
    named_table: true,
    keypos: 1,

    # Tweaks
    read_concurrency: true,
    write_concurrency: true,
    decentralized_counters: false,
    compressed: false
  ]

  # From https://erlang.org/doc/man/dets.html#info-2
  @dets_info_items [
    :access,
    :auto_save,
    :bchunk_format,
    :hash,
    :file_size,
    :filename,
    :keypos,
    :memory,
    :no_keys,
    :no_objects,
    :no_slots,
    :owner,
    :ram_file,
    :safe_fixed,
    :safe_fixed_monotonic_time,
    :size,
    :type
  ]
  # From https://erlang.org/doc/man/ets.html#info-2
  @ets_info_items [
    :binary,
    :compressed,
    :decentralized_counters,
    :fixed,
    :heir,
    :id,
    :keypos,
    :memory,
    :name,
    :named_table,
    :node,
    :owner,
    :protection,
    :safe_fixed,
    :safe_fixed_monotonic_time,
    :size,
    :stats,
    :type,
    :write_concurrency,
    :read_concurrency
  ]

  # Implemented
  # x info/1
  # x info/2
  # x get/3         !!!
  # x put/3         !!!
  # x delete/2      !!!
  # x has_key?/2
  # x keys/1

  # TODO:
  # new
  # merge
  # save_as/2
  # to_map/1
  # to_list
  # to_stream
  # truncate
  # ---
  # {:ok, pid} = Pockets.new(:ets_cache)
  # Pockets.from_file("/tmp/something")
  # ---
  # {:ok, pid} = Pockets.open(:ets_cache)
  # {:ok, pid2} = Pockets.open(:disk_cache, "/tmp/something")
  # pid = Pockets.merge(pid, pid2)


  # From Map:
  # ----------
  # drop/2
  # equal?/2
  # fetch/2
  # fetch!/2
  # get_lazy/3
  # merge/2       !!!
  # merge/3
  # new
  # new/1 <-- ??? e.g. how to change an enumerable into a dets map for persistence (???)
  # pop/3
  # pop!/3
  # pop_lazy/3
  # put_new/3
  # put_new_lazy/3
  # replace!/3
  # split ???
  # take/2 ???
  # update/4 (meh)
  # update!/4 (meh)
  # values/1

  # From Stash et al
  # -------------
  # clear/1 removes all items. flush? truncate?
  # empty?/1
  # dec/4
  # inc/4

  # new
  # load/2 from file ...
  # persist/2 to file  !!!
  # size/1
  # drop_table/1
  # all -- show all tables...

  @doc """
  Deletes the entry in table for a specific `key`
  """
  def delete(table, key), do: GenServer.call(table, {:delete, key, table})

  @doc """
  Gets the value for a specific `key` in the table.
  """
  def get(table, key, default \\ nil), do: GenServer.call(table, {:get, key, default})

  @impl true
  # :dets.delete returns :ok on success, {:error, reason} on fail
  def handle_call({:delete, key, pid}, _from, %DetsTable{table_ref: table_ref} = state) do
    case :dets.delete(table_ref, key) do
      :ok -> {:reply, pid, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  # :ets.delete returns true on success
  def handle_call({:delete, key, pid}, _from, %EtsTable{table_ref: table_ref} = state) do
    case :ets.delete(table_ref, key) do
      true -> {:reply, pid, state}
      _ -> {:reply, {:error, "There was a problem deleting the key #{key} from the table #{table_ref}"}, state}
    end
  end

  @impl true
  def handle_call({:get, key, default}, _from, %DetsTable{table_ref: table_ref} = state) do
    value = table_ref
            |> :dets.lookup(key)
            |> case do
                 [{ ^key, value }] -> value
                 _unrecognised_val -> default
               end

    {:reply, value, state}
  end

  @impl true
  def handle_call({:get, key, default}, _from, %EtsTable{table_ref: table_ref} = state) do
    value = table_ref
    |> :ets.lookup(key)
    |> case do
      [{ ^key, value }] -> value
      _unrecognised_val -> default
    end

    {:reply, value, state}
  end

  @impl true
  def handle_call({:has_key?, key}, _from, %DetsTable{table_ref: table_ref} = state) do
    :dets.member(table_ref, key)
  end

  @impl true
  def handle_call({:has_key?, key}, _from, %EtsTable{table_ref: table_ref} = state) do
    :ets.member(table_ref, key)
  end

  @impl true
  def handle_call({:info}, _from, %DetsTable{table_ref: table_ref, name: name} = state) do
    state = table_ref
    |> :dets.info()
    |> DetsTable.from_list(name)

    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:info}, _from, %EtsTable{table_ref: table_ref} = state) do
    state = table_ref
    |> :ets.info()
    |> EtsTable.from_list()

    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:info, item}, _from, %DetsTable{table_ref: table_ref, name: name} = state) when item in @dets_info_items do
    {:reply, :dets.info(table_ref, item), state}
  end

  @impl true
  def handle_call({:keys}, _from, %EtsTable{table_ref: table_ref} = state) do
    {:reply, get_keys_lazy(table_ref, :ets) |> Enum.to_list(), state}
  end

  @impl true
  def handle_call({:keys}, _from, %DetsTable{table_ref: table_ref} = state) do
    {:reply, get_keys_lazy(table_ref, :dets) |> Enum.to_list(), state}
  end

  @impl true
  def handle_call({:info, item}, _from, %EtsTable{table_ref: table_ref} = state) when item in @ets_info_items do
    {:reply, :ets.info(table_ref, item), state}
  end

  @impl true
  # :dets.insert returns :ok on success, {:error, reason} on fail
  def handle_call({:put, key, value, pid}, _from, %DetsTable{table_ref: table_ref} = state) do
    case :dets.insert(table_ref, {key, value}) do
      :ok -> {:reply, pid, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  # :ets.insert returns true on success
  def handle_call({:put, key, value, pid}, _from, %EtsTable{table_ref: table_ref} = state) do
    case :ets.insert(table_ref, {key, value}) do
      true -> {:reply, pid, state}
      _ -> {:reply, {:error, "There was a problem putting the value into the table #{table_ref}"}, state}
    end
  end

  @doc """
  Checks if the table has the given key.
  """
  def has_key?(table, key), do: GenServer.call(table, {:has_key?, key})

  @doc """
  Gets info about the given table.
  """
  def info(table), do: GenServer.call(table, {:info})

  @doc """
  Gets info about the given `item` in the table. The available items depend on the type of table.
  """
  def info(table, item), do: GenServer.call(table, {:info, item})

  @impl true
  def init(state), do: {:ok, state}

  @doc """
  Gets a list of keys in the given table.
  """
  def keys(table), do: GenServer.call(table, {:keys})

  @doc """
  Open a table for use. If the table does not exist, it will be created with the `opts` provided.
  If the table has already been opened, a warning is issued.

  The second argument specifies the storage mechanism for the table, either a path to a file (as a string)
  if the table is to be stored in a file (i.e. a DETS table), or `:memory` if the table is to be kept only in memory
  (i.e. an ETS table).

  The `opts` pertains to the type table that is being opened:

  - `:memory` : default arguments: #{inspect(@default_ets_opts)}
  - filepath : default arguments: #{inspect(@default_dets_opts)}

  ## Examples

      iex>
  """
  @spec open(table_name :: atom, :disk | binary, opts :: keyword) :: any
  def open(table_name, storage \\ :memory, opts \\ [type: @default_table_type])

  # :ets.new/2 will throw an ArgumentError if you try to create the same named table more than once
  # ETS
  def open(table_name, :memory, opts) when is_atom(table_name) do
    table_name
    |> :ets.info()
    |> open_or_create_ets_table(table_name, opts)
    |> case do
      {:ok, state} -> GenServer.start_link(__MODULE__, state, name: table_name)
      {:error, error} -> {:error, error}
    end
  end

  # DETS
  def open(table_name, file, opts) when is_atom(table_name) and is_binary(file) do
    opts = Keyword.merge(@default_dets_opts, opts)

    file
    |> File.exists?()
    |> open_or_create_dets_table(file, table_name, opts)
    |> populate_dets_info(table_name)
    |> case do
      {:ok, state} -> GenServer.start_link(__MODULE__, state, name: table_name)
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Puts the given `value` under `key` in `table`.
  """
  def put(table, key, value), do: GenServer.call(table, {:put, key, value, table})

  def save_as(table, target_file) do
    # TODO
    # See Stash.persist:
    #     case :dets.open_file(path, gen_dts_args(cache)) do
    #      { :ok, ^path } ->
    #        :dets.from_ets(path, cache)
    #        :dets.close(path)
    #      error_state -> error_state
    #    end
  end

  @doc """
  Outputs the contents of the `table` to a list.

  Although this is useful for debugging purposes, for larger data sets consider using `to_stream/1` instead.
  """
  def to_list(table), do: GenServer.call(table, {:to_list})

  @doc """
  Outputs the contents of the `table` to a map.

  Although this is useful for debugging purposes, for larger data sets consider using `to_stream/1` instead.
  """
  def to_map(table), do: GenServer.call(table, {:to_map})

  @doc """
  Outputs the contents of the `table` to a stream for lazy evaluation.
  """
  def to_stream(table), do: GenServer.call(table, {:to_stream})

  # Adapted from https://stackoverflow.com/questions/35122608/how-to-retrieve-a-list-of-ets-keys-without-scanning-entire-table
  defp get_keys_lazy(table_name, lib) when is_atom(table_name) do
    Stream.resource(
      fn -> [] end,
      fn acc ->
        case acc do
          [] ->
            case lib.first(table_name) do
              :"$end_of_table" -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case lib.next(table_name, acc) do
              :"$end_of_table" -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,

      fn _acc -> :ok end
    )
  end

  defp get_contents_lazy(table_name, lib) when is_atom(table_name) do
    Stream.resource(
      fn -> [] end,
      fn acc ->
        case acc do
          [] ->
            case lib.first(table_name) do
              :"$end_of_table" -> {:halt, acc}
              first_key -> {[{first_key, "TODO"}], first_key}
            end

          acc ->
            case lib.next(table_name, acc) do
              :"$end_of_table" -> {:halt, acc}
              next_key -> {[{next_key, "TODO"}], next_key}
            end
        end
      end,

      fn _acc -> :ok end
    )
  end


  defp open_or_create_ets_table(:undefined, table_name, opts) do
    opts =
      @default_ets_opts
      |> Keyword.merge(opts)
      |> prepare_ets_options()

    {:ok,
     table_name
     |> :ets.new(opts)
     |> :ets.info()
     |> EtsTable.from_list()}
  rescue
    e in ArgumentError -> {:error, "Error opening ETS table: #{inspect(e)}"}
  end

  defp open_or_create_ets_table(info, table_name, opts) do
    Logger.warn("Table already exists: #{table_name}")
    {:ok, EtsTable.from_list(info)}
  end

  defp open_or_create_dets_table(true, file, table_name, opts) do
    file_as_atom = String.to_atom(file)

    file_as_atom
    |> :dets.is_dets_file()
    |> case do
      true -> :dets.open_file(file_as_atom, opts)
      false -> {:error, "File is not a :dets file: #{file}"}
    end
  end

  defp open_or_create_dets_table(false, file, table_name, opts) do
    file
    |> Path.dirname()
    |> File.mkdir_p()
    |> case do
      :ok ->
        file
        |> String.to_atom()
        |> :dets.open_file(opts)

      {:error, error} ->
        {:error, error}
    end
  end

  defp populate_dets_info({:ok, table_ref}, table_name) do
    {:ok,
     table_ref
     |> :dets.info()
     |> DetsTable.from_list(table_name)}
  end

  defp populate_dets_info({:error, error}, _), do: {:error, error}

  # :ets.new/2 does not take a nice keyword list as its options: it takes a mix of values. Yuck.
  defp prepare_ets_options(opts) do
    relevant_opts = Keyword.take(opts, Keyword.keys(@default_ets_opts))

    prepped =
      Keyword.take(relevant_opts, [
        :read_concurrency,
        :write_concurrency,
        :decentralized_counters,
        :keypos
      ]) ++
        [Keyword.get(opts, :type, @default_table_type)] ++
        [Keyword.get(opts, :access, :public)]

    [:compressed, :named_table]
    |> Enum.reduce(prepped, fn x, acc ->
      case Keyword.get(relevant_opts, x, false) do
        false -> acc
        true -> acc ++ [x]
      end
    end)
  end

  defp create_path_and_open_file(file, opts) do
    file
    |> Path.dirname()
    |> File.mkdir_p()
    |> case do
      :ok ->
        file
        |> String.to_atom()
        |> :dets.open_file(opts)

      {:error, error} ->
        {:error, error}
    end
  end

  #  @impl true
  #  def terminate(reason, state) do
  #
  #  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("#{inspect(reason)} --------------------------------------------------")
  end
end
