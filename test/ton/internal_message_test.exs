defmodule Ton.InternalMessageTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.InternalMessage

  describe "serialize/1" do
    test "serializes an internal message (1)" do
      {:ok, address} = Address.parse("0QCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjBmp")
      internal_message = InternalMessage.new(to: address, value: 1, bounce: true)

      assert %Ton.Cell{
               refs: [],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 392
               },
               kind: :ordinary
             } = InternalMessage.serialize(internal_message)

      assert "620040100806a0f20bf4a0f32306238c8f1c50a17daa72027b7f0ee334ad6db954c608080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end

    test "serializes an internal message (2)" do
      {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")
      internal_message = InternalMessage.new(to: address, value: 1, bounce: false)

      assert %Ton.Cell{
               refs: [],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 392
               },
               kind: :ordinary
             } = InternalMessage.serialize(internal_message)

      assert "42000392875059b1ac00bd98d8fd97394d50d33bccb431fa5413b77b28426795860d88080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end

    test "serializes an internal message with comment" do
      {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")
      internal_message = InternalMessage.new(to: address, value: 1, bounce: false, body: "Hello")

      assert %Ton.Cell{
               refs: [],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 432
               },
               kind: :ordinary
             } = InternalMessage.serialize(internal_message)

      assert "42000392875059b1ac00bd98d8fd97394d50d33bccb431fa5413b77b28426795860d88080000000000000000000000000048656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end
  end
end
