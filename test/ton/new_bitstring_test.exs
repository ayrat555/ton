defmodule Ton.NewBitstringTest do
  use ExUnit.Case

  alias Ton.NewBitstring

  describe "at/2" do
    test "reads bits" do
      bitstring = NewBitstring.new([170], 0, 8)

      assert true == NewBitstring.at(bitstring, 0)
      assert false == NewBitstring.at(bitstring, 1)
      assert true == NewBitstring.at(bitstring, 2)
      assert false == NewBitstring.at(bitstring, 3)
      assert true == NewBitstring.at(bitstring, 4)
      assert false == NewBitstring.at(bitstring, 5)
      assert true == NewBitstring.at(bitstring, 6)
      assert false == NewBitstring.at(bitstring, 7)
    end
  end

  describe "equal?/2" do
    test "compares bitstrings" do
      a = NewBitstring.new([170], 0, 8)
      b = NewBitstring.new([170], 0, 8)
      c = NewBitstring.new([0, 170], 8, 8)
      d = NewBitstring.new([0, 169], 8, 8)
      e = NewBitstring.new([169], 0, 8)

      assert NewBitstring.equal?(a, b)
      assert NewBitstring.equal?(b, a)
      assert NewBitstring.equal?(a, c)
      assert NewBitstring.equal?(c, a)
      refute NewBitstring.equal?(a, d)
      refute NewBitstring.equal?(a, e)
    end
  end

  describe "subbufer/3" do
    test "returns subbufer" do
      bitstring = NewBitstring.new([1, 2, 3, 4, 5, 6, 7, 8], 0, 64)
      subbuffer = NewBitstring.subbuffer(bitstring, 0, 16)

      assert [1, 2] == subbuffer
    end
  end
end
