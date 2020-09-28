# Pockets : Overview

`Pockets` is an Elixir wrapper around Erlang [ETS](https://erlang.org/doc/man/ets.html) and [DETS](https://erlang.org/doc/man/dets.html), Erlang's built-in term storage and disk-based term storage. `Pockets` aims to provide a simple and familiar interface for caching and persisting data by implementing many of the functions found in the built-in `Map` and `Keyword` modules. A pocket may hold data in memory or on disk.

## Examples

A simple memory-based cache requires no special arguments:

```
iex> Pockets.new(:my_cache)
{:ok, :my_cache}
iex> Pockets.put(:my_cache, :a, "Apple") |> Pockets.put(:b, "boy") |> Pockets.put(:c, "Charlie")
:my_cache
iex> Pockets.get(:my_cache, :c)
"Charlie"
```

Using a disk-based cache is appropriate when you need your data to persist, just supply a file path as the second argument:

```
iex> Pockets.new(:on_disk, "/tmp/cache.dets")
{:ok, :on_disk}
```

You can easily populate your pocket with existing data:

```
iex> Pockets.new(:on_disk, "/tmp/cache.dets")
{:ok, :on_disk}
iex> Pockets.merge(:on_disk, %{x: "xylophone", y: "yellow"})
:on_disk
```

You can easily inspect your data, e.g. using `Pockets.to_map/1`:

```
iex> Pockets.to_map(:on_disk)
%{x: "xylophone", y: "yellow"}
```
