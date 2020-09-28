defmodule Pockets do
  @moduledoc """
  `Pockets` is a wrapper around Erlang [`:ets`](https://erlang.org/doc/man/ets.html)
  and [`:dets``](https://erlang.org/doc/man/dets.html), built-in options for memory- and disk-based term storage.
  It offers simple key/value storage using an interface similar to the `Map` or `Keyword` modules. This can be a useful
  persistent cache for many use cases.

  For those needing more power or versatility than what `:ets` or `:dets` can offer, Elixir includes
  [`:mnesia`](http://erlang.org/doc/man/mnesia.html).

  Note that this package and the libraries that underpin it may have limitations or specific behaviors that may affect
  its suitability for various use-cases.  For example, the limited support for concurrency provided by the `:ets(3)`
  module is not yet provided by `:dets`.

  Support for `:bag`, `:duplicate_bag` types has not yet been tested.

  See also

  - [stash](https://github.com/whitfin/stash)
  - ["What is ETS in Elixir?"](https://culttt.com/2016/10/05/what-is-ets-in-elixir/)
  """

  alias Pockets.{DetsInfo, EtsInfo, Table, Registry}

  require Logger

  @typedoc """
  An alias is used to refer to a `Pockets` table: it is usually an atom, but in some cases
  it may be a reference.
  """
  @type alias :: atom | reference

  defguard is_alias(value) when is_atom(value) or is_reference(value)

  # @table_types [:bag, :duplicate_bag, :set]

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

  # TODO:
  # inc, dec
  # map (apply function to each element in a table) :dets.traverse/2 | :ets.??? fun2ms + select_replace
  # detect() -- all/0 -- census/0 load all known :ets and :dets tables into Pocket for reference/inspection

  @doc """
  Deletes the entry in table for a specific `key`

  ## Examples

      iex> Pockets.new(:my_cache)
      {:ok, :my_cache}
      iex> Pockets.merge(:my_cache, %{a: "apple", b: "boy", c: "cat"})
      :my_cache
      iex> Pockets.to_map(:my_cache)
      %{a: "apple", b: "boy", c: "cat"}
      iex> Pockets.delete(:my_cache, :b)
      :my_cache
      iex> Pockets.to_map(:my_cache)
      %{a: "apple", c: "cat"}
  """
  @spec delete(table_alias :: alias, any) :: alias | {:error, any}
  def delete(table_alias, key) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> case do
      nil -> {:error, "Pockets table not found: #{table_alias}"}
      table -> do_delete(table, key)
    end
  end

  @doc """
  Destroys the given table.
  For disk-based (`:dets`) tables, this will delete the backing file.
  For memory-based (`:ets`) tables, this destroys the table and its contents.

  ## Examples

      iex> Pockets.new(:my_cache, "/tmp/cache.dets")
      {:ok, :my_cache}
      iex> Pockets.destroy(:my_cache)
      :ok
  """
  @spec destroy(table_alias :: alias) :: :ok | {:error, any}
  def destroy(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_destroy()
    |> case do
      :ok -> Registry.unregister(table_alias)
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Checks if the given table is empty.

  ## Examples

      iex> {:ok, tid} = Pockets.new(:my_cache)
      {:ok, :my_cache}
      iex> Pockets.empty?(tid)
      true
  """
  @spec empty?(table_alias :: Pockets.alias()) :: boolean
  def empty?(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_info(:size) == 0
  end

  @doc """
  Gets the value for a specific `key` in the table.
  """
  @spec get(table_alias :: alias, any, any) :: alias
  def get(table_alias, key, default \\ nil) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_get(key, default)
  end

  @doc """
  Checks if the table has the given key.
  """
  @spec has_key?(table_alias :: alias, any) :: boolean
  def has_key?(table_alias, key) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_has_key?(key)
  end

  @doc """
  Gets info about the given table.
  """
  @spec info(table_alias :: alias) :: EtsInfo.t() | DetsInfo.t()
  def info(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_info()
  end

  @doc """
  Gets info about the given `item` in the table. The available items depend on the type of table.
  """
  @spec info(table_alias :: alias, atom) :: any
  def info(table_alias, item) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_info(item)
  end

  @doc """
  Gets a list of keys in the given table. For larger tables, consider `keys_stream/1`
  """
  @spec keys(table_alias :: alias) :: list
  def keys(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> get_keys_lazy()
    |> Enum.to_list()
  end

  @doc """
  Gets a list of keys in the given table as a stream.
  """
  def keys_stream(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> get_keys_lazy()
  end

  @doc """
  This is a powerful function that lets you merge `input` into an open table.
  All data in the input will be added to the table: the keys in the `input` "have precedence"
  over pre-existing keys in the table.

  When the `input` to be merged is...

    - an alias for another table, the contents from that table are added to the given `table_alias`
    - a map, the contents from the map are added into the given `table_alias`
    - a list, the contents from the list are added into the given `table_alias`

  ## Examples

      # Merging a map into a table:
      iex> Pockets.new(:my_cache)
      {:ok, :my_cache}
      iex> Pockets.merge(:my_cache, %{a: "apple", b: "boy", c: "cat"})
      :my_cache
      iex> Pockets.to_map(:my_cache)
      %{a: "apple", b: "boy", c: "cat"}

      # Merging two tables:
      iex> Pockets.new(:my_first)
      {:ok, :my_first}
      iex> Pockets.merge(:my_first, %{a: "apple", b: "boy", c: "cat"})
      :my_first
      iex> Pockets.new(:my_second)
      {:ok, :my_second}
      iex> Pockets.merge(:my_second, %{x: "xray", y: "yellow", z: "zebra"})
      :my_second
      iex> Pockets.merge(:my_first, :my_second)
      :my_first
      iex> Pockets.to_map(:my_first)
      %{a: "apple", b: "boy", c: "cat", x: "xray", y: "yellow", z: "zebra"}
  """
  @spec merge(alias(), input :: alias | list | map) :: alias
  def merge(table_alias, input) when is_alias(table_alias) and is_alias(input) do
    table2 = Registry.lookup(input)

    table_alias
    |> Registry.lookup()
    |> do_merge_tables(table2)
  end

  def merge(table_alias, input) when is_alias(table_alias) when is_map(input) or is_list(input) do
    table_alias
    |> Registry.lookup()
    |> do_merge_enum(input)
  end

  @doc """
  Creates a new table either in memory (default) or on disk.

  The second argument specifies the storage mechanism for the table, either a path to a file (as a string)
  for disk-backed tables (`:dets`), or in `:memory` for memory-backed tables (`:ets`).

  The `opts` pertains to the type table that is being opened:

  - `:memory` : default arguments: #{inspect(@default_ets_opts)}
  - filepath : default arguments: #{inspect(@default_dets_opts)}

  ## Examples

      iex> Pockets.new(:ram_cache, :memory)
      {:ok, :ram_cache}
  """
  @spec new(table_alias :: alias, :memory | binary, opts :: keyword) ::
          {:ok, alias} | {:error, any}
  def new(table_alias, storage \\ :memory, opts \\ [type: @default_table_type])

  def new(table_alias, :memory, opts) when is_alias(table_alias) do
    table_alias
    |> Registry.exists?()
    |> case do
      true -> {:noop, "Table #{table_alias} already exists"}
      false -> create_table(table_alias, opts, :ets)
    end
  end

  def new(table_alias, file, opts) when is_alias(table_alias) and is_binary(file) do
    opts = Keyword.merge(@default_dets_opts, opts)
    type = Keyword.get(opts, :type, @default_table_type)

    file
    |> File.exists?()
    |> case do
      true ->
        {:error, "File already exists"}

      false ->
        with :ok <- prepare_directory(file),
             {:ok, tid} <- create_table(file, opts, :dets) do
          Registry.register(
            table_alias,
            %Table{
              library: :dets,
              alias: table_alias,
              tid: tid,
              type: type,
              opts: opts
            }
          )
        else
          {:error, error} -> {:error, error}
        end
    end
  end

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

      iex> Pockets.open(:my_cache)
      {:ok, :my_cache}
      iex> Pockets.open(:my_cache, :memory)
      {:ok, :my_cache}
      iex> Pockets.open(:disk_cache, "/tmp/cache.dets")
      {:ok, :disk_cache}
  """
  @spec open(Pocekts.alias(), :memory | binary, opts :: keyword) :: any
  def open(table_alias, storage \\ :memory, opts \\ [type: @default_table_type])

  # :ets.new/2 will throw an ArgumentError if you try to create the same named table more than once
  # :ets
  def open(table_alias, :memory, opts) when is_alias(table_alias) do
    table_alias
    |> :ets.info()
    |> case do
      :undefined -> create_table(table_alias, opts, :ets)
      _ -> {:exists, table_alias}
    end
  end

  # :dets
  def open(table_alias, file, opts) when is_alias(table_alias) and is_binary(file) do
    {create?, opts} =
      @default_dets_opts
      |> Keyword.merge(opts)
      |> Keyword.pop(:create?, false)

    file
    |> File.exists?()
    |> case do
      true -> open_and_register_dets_file(table_alias, file, opts)
      false -> maybe_create_and_register_dets_file(create?, table_alias, file, opts)
    end
  end

  @doc """
  Puts the given `value` under `key` in given table.
  """
  @spec put(table_alias :: alias, any, any) :: alias
  def put(table_alias, key, value) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_put(key, value)
  end

  @doc """
  Both `:ets` and `:dets` files can be saved to disk. You can use this function to persist an in-memory `:ets`
  file to disk for later use, or you can use it to make a copy of an existing `:dets` table.

  The target file must not be in use by another table; if the target file exists this will return an error
  unless the `:overwrite?` option is set to true.

  Options:

  - overwrite? default: `false`
  """
  @spec save_as(table_alias :: alias, binary, keyword) :: :ok | {:error, any}
  def save_as(table_alias, target_file, opts \\ [])
      when is_alias(table_alias) and is_binary(target_file) do
    table_alias
    |> Registry.lookup()
    |> case do
      nil -> {:error, "Table alias not found #{table_alias}"}
      table -> do_save_as(table, target_file, opts)
    end
  end

  @doc """
  Show all registered `Pockets` tables.

  ## Examples

      iex> Pockets.show_tables()
      [%Pockets.Table{alias: :my_cache, library: :ets, tid: :my_cache, type: :set}]
  """
  def show_tables(_opts \\ []) do
    Registry.list()
    |> Map.values()
  end

  @doc """
  Returns the size of the given table, measured by the number of entries.
  """
  @spec size(table_alias :: Pockets.alias()) :: integer
  def size(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> do_info(:size)
  end

  @doc """
  Outputs the contents of the given table to a list.

  Although this is useful for debugging purposes, for larger data sets consider using `to_stream/1` instead.
  """
  @spec to_list(table_alias :: alias) :: list
  def to_list(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> get_contents_lazy()
    |> Enum.to_list()
  end

  @doc """
  Outputs the contents of the table to a map.

  Although this is useful for debugging purposes, for larger data sets consider using `to_stream/1` instead.
  """
  @spec to_map(table_alias :: alias) :: map
  def to_map(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> get_contents_lazy()
    |> Enum.into(%{})
  end

  @doc """
  Outputs the contents of the table to a stream for lazy evaluation.
  """
  def to_stream(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> get_contents_lazy()
  end

  @doc """
  Truncates the given table; this removes all entries from the table while leaving its options in tact.

  ## Examples

      iex> Pockets.put(:my_cache, :a, "Apple") |> Pockets.put(:b, "boy") |> Pockets.put(:c, "Charlie")
      :my_cache
      iex> Pockets.truncate(:my_cache)
      :my_cache
      iex> Pockets.to_map(:my_cache)
      %{}
  """
  @spec truncate(table_alias :: alias) :: alias | {:error, any}
  def truncate(table_alias) when is_alias(table_alias) do
    table_alias
    |> Registry.lookup()
    |> case do
      %{library: library, tid: tid} ->
        case library.delete_all_objects(tid) do
          :ok -> table_alias
          true -> table_alias
          {:error, error} -> {:error, error}
        end

      nil ->
        {:error, "Table not found: #{table_alias}"}
    end
  end

  # -----------------------------------------------------------------------------
  defp open_and_register_dets_file(table_alias, file, opts) do
    file_as_atom = String.to_atom(file)

    with true <- :dets.is_dets_file(file_as_atom),
         {:ok, tid} <- :dets.open_file(file_as_atom, opts) do
      Registry.register(
        table_alias,
        %Table{
          library: :dets,
          alias: table_alias,
          tid: tid,
          type: Keyword.get(opts, :type, @default_table_type),
          opts: opts
        }
      )
    else
      false -> {:error, "File is not a :dets file: #{file}"}
      {:error, error} -> {:error, error}
    end
  end

  defp maybe_create_and_register_dets_file(false, _, file, _) do
    {
      :error,
      "File not found: #{file}. Will not create file unless `create?: true` given as option."
    }
  end

  defp maybe_create_and_register_dets_file(true, table_alias, file, opts) do
    with false <- is_file_already_in_use?(file),
         :ok <- prepare_directory(file),
         {:ok, tid} <- create_table(file, opts, :dets) do
      Registry.register(
        table_alias,
        %Table{
          library: :dets,
          alias: table_alias,
          tid: tid,
          type: Keyword.get(opts, :type, @default_table_type),
          opts: opts
        }
      )
    else
      true -> {:error, "File is already in use by another :dets table: #{file}"}
      {:error, error} -> {:error, error}
    end
  end

  defp create_table(file, opts, :dets) do
    file
    |> String.to_atom()
    |> :dets.open_file(opts)
  end

  defp create_table(table_alias, opts, :ets) do
    type = Keyword.get(opts, :type, @default_table_type)

    opts =
      @default_ets_opts
      |> Keyword.merge(opts)
      |> prepare_ets_options()

    tid = :ets.new(table_alias, opts)

    Registry.register(table_alias, %Table{
      library: :ets,
      alias: table_alias,
      tid: tid,
      type: type,
      opts: opts
    })
  rescue
    e in ArgumentError -> {:error, "Error creating :ets table: #{inspect(e)}"}
  end

  # Adapted from https://stackoverflow.com/questions/35122608/how-to-retrieve-a-list-of-ets-keys-without-scanning-entire-table
  defp get_keys_lazy(%{tid: tid, library: library}) do
    Stream.resource(
      fn -> [] end,
      fn acc ->
        case acc do
          [] ->
            case library.first(tid) do
              :"$end_of_table" -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case library.next(tid, acc) do
              :"$end_of_table" -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,
      fn _acc -> :ok end
    )
  end

  defp get_contents_lazy(%{tid: tid, library: library}) do
    Stream.resource(
      fn -> [] end,
      fn acc ->
        case acc do
          [] ->
            case library.first(tid) do
              :"$end_of_table" -> {:halt, acc}
              first_key -> {library.lookup(tid, first_key), first_key}
            end

          acc ->
            case library.next(tid, acc) do
              :"$end_of_table" -> {:halt, acc}
              next_key -> {library.lookup(tid, next_key), next_key}
            end
        end
      end,
      fn _acc -> :ok end
    )
  end

  # :ets.new/2 does not take a nice keyword list as its options: it takes a mix of values. Yuck.
  defp prepare_ets_options(opts) do
    relevant_opts = Keyword.take(opts, Keyword.keys(@default_ets_opts))

    prepped =
      Keyword.take(
        relevant_opts,
        [
          :read_concurrency,
          :write_concurrency,
          :decentralized_counters,
          :keypos
        ]
      ) ++
        [Keyword.get(opts, :type, @default_table_type)] ++
        [Keyword.get(opts, :access, :public)]

    [:compressed, :named_table]
    |> Enum.reduce(
      prepped,
      fn x, acc ->
        case Keyword.get(relevant_opts, x, false) do
          false -> acc
          true -> acc ++ [x]
        end
      end
    )
  end

  @spec prepare_directory(binary) :: :ok | {:error, any}
  defp prepare_directory(file) do
    file
    |> Path.dirname()
    |> File.mkdir_p()
  end

  # :dets.delete returns :ok on success, {:error, reason} on fail
  defp do_delete(%Table{library: :dets, alias: alias, tid: tid}, key) do
    case :dets.delete(tid, key) do
      :ok -> alias
      {:error, error} -> {:error, error}
    end
  end

  # :ets.delete returns true on success
  defp do_delete(%Table{library: :ets, alias: alias, tid: tid}, key) do
    case :ets.delete(tid, key) do
      true -> alias
      _ -> {:error, "There was a problem deleting the key #{key} from the table #{alias}"}
    end
  end

  defp do_destroy(%Table{library: :dets, tid: tid} = table) do
    with %DetsInfo{filename: filename} <- do_info(table),
         :ok <- :dets.close(tid) do
      filename
      # <-- req'd???
      |> to_string()
      |> File.rm()
    else
      {:error, error} -> {:error, error}
    end
  end

  defp do_destroy(%Table{library: :ets, alias: alias, tid: tid}) do
    case :ets.delete(tid) do
      true -> :ok
      _ -> {:error, "There was a problem destroying the table #{alias}"}
    end
  end

  # Shared functionality!
  defp do_get(%Table{library: library, tid: tid}, key, default) do
    # TODO: if :bag, value might be like `[x: 1, x: 2, x: 3]`
    tid
    |> library.lookup(key)
    |> case do
      [{^key, value}] -> value
      _unrecognised_val -> default
    end
  end

  defp do_has_key?(%Table{library: library, tid: tid}, key) do
    library.member(tid, key)
  end

  defp do_info(%Table{library: :dets, tid: tid}) do
    tid
    |> :dets.info()
    |> DetsInfo.new()
  end

  defp do_info(%Table{library: :ets, tid: tid}) do
    tid
    |> :ets.info()
    |> EtsInfo.new()
  end

  defp do_info(%Table{library: :dets, tid: tid}, item) when item in @dets_info_items do
    :dets.info(tid, item)
  end

  defp do_info(%Table{library: :ets, tid: tid}, item) when item in @ets_info_items do
    :ets.info(tid, item)
  end

  defp do_merge_tables(t1, t2) do
    t2
    |> get_contents_lazy()
    |> Enum.each(fn {k, v} -> do_put(t1, k, v) end)

    t1.alias
  end

  defp do_merge_enum(%Table{alias: table_alias} = table, enumerable) do
    enumerable
    |> Enum.each(fn {k, v} ->
      do_put(table, k, v)
    end)

    table_alias
  end

  # :dets.insert returns :ok on success, {:error, reason} on fail
  defp do_put(%Table{library: :dets, tid: tid, alias: alias}, key, value) do
    case :dets.insert(tid, {key, value}) do
      :ok -> alias
      {:error, error} -> {:error, error}
    end
  end

  defp do_put(%Table{library: :ets, tid: tid, alias: alias}, key, value) do
    case :ets.insert(tid, {key, value}) do
      true -> alias
      _ -> {:error, "There was a problem putting into your table #{alias}"}
    end
  end

  # Save a copy : do a file operation
  defp do_save_as(%Table{library: :dets, tid: tid, opts: dets_opts}, target_file, opts) do
    source_file = to_string(:dets.info(tid)[:filename])

    case source_file == target_file do
      true ->
        :dets.sync(tid)

      false ->
        with false <- is_file_already_in_use?(target_file),
             :ok <- ok_to_write(target_file, opts),
             :ok <- :dets.close(tid),
             :ok <- File.cp(source_file, target_file),
             {:ok, _} <- :dets.open_file(tid, dets_opts) do
          :ok
        else
          true -> {:error, "File is in use by another open :dets table #{target_file}"}
          {:error, error} -> {:error, error}
        end
    end
  end

  # Persist an :ets table to disk
  defp do_save_as(%Table{library: :ets, tid: tid, type: type}, target_file, _opts) do
    target_tid = String.to_atom(target_file)

    case :dets.open_file(target_tid, type: type) do
      {:ok, ^target_tid} ->
        :dets.from_ets(target_tid, tid)
        :dets.close(target_tid)

      {:error, error} ->
        {:error, error}
    end
  end

  defp ok_to_write(file, opts) do
    case File.exists?(file) do
      true ->
        case Keyword.get(opts, :overwrite?, false) do
          true -> :ok
          false -> {:error, "File exists: #{file} - will not overwrite unless `overwrite?: true`"}
        end

      false ->
        :ok
    end
  end

  # Is the file already used by any :dets table?
  defp is_file_already_in_use?(file) do
    file_as_atom = String.to_atom(file)

    :dets.all()
    |> Enum.find(
      false,
      fn x ->
        x
        |> :dets.info()
        |> DetsInfo.new()
        |> case do
          %DetsInfo{filename: ^file_as_atom} -> true
          _ -> false
        end
      end
    )
  end
end
