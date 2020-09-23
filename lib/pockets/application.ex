defmodule Pockets.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Pockets.Registry, []}
    ]

    opts = [strategy: :one_for_one, name: Pockets.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
