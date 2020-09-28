defmodule Pockets.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("Starting up Pockets")

    children = [
      {Pockets.Registry, []}
    ]

    opts = [strategy: :one_for_one, name: Pockets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def prep_stop(_) do
    Logger.debug("Prepping stop Pockets")
    File.write!("/tmp/prep_stop.txt", "prep_stop")
  end

  def stop(_) do
    Logger.debug("Stopping up Pockets")
    File.write!("/tmp/stop.txt", "stop")
  end
end
