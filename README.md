# Pockets

[![Module Version](https://img.shields.io/hexpm/v/pockets.svg)](https://hex.pm/packages/pockets)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/pockets/)
[![Total Download](https://img.shields.io/hexpm/dt/pockets.svg)](https://hex.pm/packages/pockets)
[![License](https://img.shields.io/hexpm/l/pockets.svg)](https://hex.pm/packages/pockets)
[![Last Updated](https://img.shields.io/github/last-commit/fireproofsocks/pockets.svg)](https://github.com/fireproofsocks/pockets/commits/master)

Pockets is an Elixir wrapper around Erlang [ETS](https://erlang.org/doc/man/ets.html) and [DETS](https://erlang.org/doc/man/dets.html), Erlang's built-in solutions for memory- and disk-based term storage. Pockets aims to provide a simple and familiar interface for caching and persisting data by implementing many of the functions found in the built-in `Map` and `Keyword` modules. A pocket may hold data in memory or on disk.

For those needing more power or versatility than what `:ets` or `:dets` can offer, Elixir includes
  [`:mnesia`](http://erlang.org/doc/man/mnesia.html).

Secondly, the docs on [erlang.org](https://erlang.org/) are a bit rough to look at for Elixir developers, so
this package acts as a case study of the differences between the powerful built-in `:ets` and `:dets` libraries.

In case it was too subtle, "Pockets" is a name that includes "ETS" for mnemonic purposes.

## Installation

Add `pockets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pockets, "~> 1.5.0"}
  ]
end
```

## Usage

A simple memory-based cache requires no special arguments:

```elixir
iex> Pockets.new(:my_cache)
{:ok, :my_cache}
iex> Pockets.put(:my_cache, :a, "Apple") |> Pockets.put(:b, "boy") |> Pockets.put(:c, "Charlie")
:my_cache
iex> Pockets.get(:my_cache, :c)
"Charlie"
```

Using a disk-based cache is appropriate when you need your data to persist. Just supply a file path as the second argument to `Pockets.new/3`:

```elixir
iex> Pockets.new(:on_disk, "/tmp/cache.dets")
{:ok, :on_disk}
```

You can easily populate your pocket with existing data:

```elixir
iex> Pockets.new(:on_disk, "/tmp/cache.dets")
{:ok, :on_disk}
iex> Pockets.merge(:on_disk, %{x: "xylophone", y: "yellow"})
:on_disk
```

You can easily inspect your data, e.g. using `Pockets.to_map/1`:

```elixir
iex> Pockets.to_map(:on_disk)
%{x: "xylophone", y: "yellow"}
```

See the `Pockets` module documentation for more info!

## Image Attribution

"pocket" by Hilmi Hidayat from the [Noun Project](https://thenounproject.com/)
