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

      assert %Ton.Bitstring{array: [1, 2, 3, 4, 5, 6, 7, 0], cursor: 61, length: 64} =
               Bitstring.set_top_upped_array(data, false)
    end
  end
end
