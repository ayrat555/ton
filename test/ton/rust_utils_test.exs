defmodule Ton.RustUtilsTest do
  use ExUnit.Case

  alias Ton.RustUtils

  describe "clz32/1" do
    test "calculates the number of leasing zero bits in the 32-bit binary representation of a number" do
      tests = [
        {1, 31},
        {4, 29},
        {1_000_000_000, 2},
        {-1000, 0}
      ]

      Enum.each(tests, fn {value, result} ->
        assert result == RustUtils.clz32(value)
      end)
    end
  end
end
