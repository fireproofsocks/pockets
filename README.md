# Pockets

Pockets is an Elixir wrapper around Erlang [ETS](https://erlang.org/doc/man/ets.html) and [DETS](https://erlang.org/doc/man/dets.html), Erlang's built-in solutions for memory- and disk-based term storage. Pockets aims to provide a simple and familiar interface for caching and persisting data by implementing many of the functions found in the built-in `Map` and `Keyword` modules. A pocket may hold data in memory or on disk.

Secondly, the docs on [erlang.org](https://erlang.org/) are a bit rough to look at for Elixir developers, so 
this package acts as a case study of the differences between the powerful built-in `:ets` and `:dets` libraries.

In case it was too subtle, "Pockets" is a name that includes "ETS" for mnemonic purposes.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pockets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pockets, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pockets](https://hexdocs.pm/pockets).


## Image Attribution

"pocket" by Hilmi Hidayat from the [Noun Project](https://thenounproject.com/)
