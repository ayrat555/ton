defmodule Ton.InternalMessageTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.InternalMessage

  describe "serialize/1" do
    test "serializes an internal message" do
      {:ok, address} = Address.parse("0QCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjBmp")
      internal_message = InternalMessage.new(to: address, value: 1, bounce: true)

      assert %Ton.Cell{
               refs: [],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 388
               },
               kind: :ordinary
             } = InternalMessage.serialize(internal_message)

      assert "68010040201a83c82fd283cc8c188e323c714285f6a9c809edfc3b8cd2b5b6e5531802020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end
  end
end
