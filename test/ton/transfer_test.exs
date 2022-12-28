defmodule Ton.TransferTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.Transfer

  setup_all do
    {:ok, address} = Address.parse("0QCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjBmp")

    params = [
      seqno: 0,
      send_mode: 5,
      value: 1,
      bounce: true,
      timeout: 60,
      to: address,
      wallet_id: 1
    ]

    %{transfer: Transfer.new(params)}
  end

  describe "serialize/1" do
    test "serializes a transfer", %{transfer: transfer} do
      assert %Ton.Cell{
               refs: [
                 %Ton.Cell{
                   refs: [],
                   data: %Ton.Bitstring{
                     length: 1023,
                     array: array,
                     cursor: 388
                   },
                   kind: :ordinary
                 }
               ],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: _,
                 cursor: 112
               },
               kind: :ordinary
             } = Transfer.serialize(transfer)

      assert "68010040201a83c82fd283cc8c188e323c714285f6a9c809edfc3b8cd2b5b6e5531802020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end
  end

  describe "serialize_and_sign/2" do
    test "seializes and signs a transfer", %{transfer: transfer} do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      assert %Ton.Cell{
               refs: [
                 %Ton.Cell{
                   refs: [],
                   data: %Ton.Bitstring{
                     length: 1023,
                     array: _,
                     cursor: 388
                   },
                   kind: :ordinary
                 }
               ],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 880
               },
               kind: :ordinary
             } = Transfer.serialize_and_sign(transfer, keypair.secret_key)

      assert "eadead429267cbaecebb5483c1fcfe2688953093bb9e34c5c9ae85d042b87a2daee252614a5ca56a035f573e007bf57c55bf6f659ef9967a5fdd2060b507890c4487a025b9e8a07bd6ce0b914bd512cf87e6881dcd99c0348cbefb8f7ceb692400000001ffffffff000000000005000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end
  end
end
