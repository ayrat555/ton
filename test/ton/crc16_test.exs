defmodule Ton.Crc16Test do
  use ExUnit.Case

  alias Ton.Crc16

  describe "calc/1" do
    test "calculate crc16" do
      data = "hello"

      assert <<195, 98>> == Crc16.calc(data)
    end
  end
end
