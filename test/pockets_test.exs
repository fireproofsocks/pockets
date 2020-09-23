defmodule PocketsTest do
  use ExUnit.Case
  doctest Pockets

  test "greets the world" do
    assert Pockets.hello() == :world
  end
end
