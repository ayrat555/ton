defmodule Ton.BitstringTest do
  use ExUnit.Case

  alias Ton.Bitstring

  describe "set_top_upped_array" do
    test "just sets the passed binary if fullfilled_bytes is true" do
      data = <<1, 2, 3, 4, 5, 6, 7, 8>>

      assert %Ton.Bitstring{length: 64, array: [1, 2, 3, 4, 5, 6, 7, 8], cursor: 64} =
               Bitstring.set_top_upped_array(data)
    end

    test "sets the passe" do
      data = <<1, 2, 3, 4, 5, 6, 7, 8>>

      assert %Ton.Bitstring{array: [1, 2, 3, 4, 5, 6, 7, 0], cursor: 60, length: 64} =
               Bitstring.set_top_upped_array(data, false)
    end
  end

  describe "new/1" do
    test "creates a new bitstring" do
      assert %Bitstring{
               length: 1023,
               array: array,
               cursor: 0
             } = Bitstring.new()

      assert Enum.count(array) == 128
    end
  end

  describe "write_uint/3" do
    test "write 32 bit uint" do
      bitstring = Bitstring.new()

      assert %Ton.Bitstring{
               length: 1023,
               array: array,
               cursor: 32
             } = Bitstring.write_uint(bitstring, 42, 32)

      assert 42 == Enum.at(array, 3)
    end
  end
end
