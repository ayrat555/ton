defmodule TonTest do
  use ExUnit.Case
  doctest Ton

  test "greets the world" do
    assert Ton.hello() == :world
  end
end
