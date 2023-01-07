defmodule Ton.TransferTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.Transfer
  alias Ton.Wallet

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
    test "serializes a transfer (1)", %{transfer: transfer} do
      assert %Ton.Cell{
               refs: [
                 %Ton.Cell{
                   refs: [],
                   data: %Ton.Bitstring{
                     length: 1023,
                     array: array,
                     cursor: 392
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

      assert "620040100806a0f20bf4a0f32306238c8f1c50a17daa72027b7f0ee334ad6db954c608080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end

    test "serializes a transfer (2)" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")

      wallet = Wallet.create(keypair.public_key)

      params = [
        seqno: 1,
        value: 1,
        bounce: false,
        to: address,
        wallet_id: wallet.wallet_id
      ]

      assert %Ton.Cell{
               refs: [
                 %Ton.Cell{
                   refs: [],
                   data: %Ton.Bitstring{
                     length: 1023,
                     array: _,
                     cursor: 392
                   },
                   kind: :ordinary
                 }
               ],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 112
               },
               kind: :ordinary
             } =
               params
               |> Transfer.new()
               |> Transfer.serialize()

      assert array
             |> :binary.list_to_bin()
             |> Base.encode16(case: :lower)
             |> String.starts_with?("29a9a3176")
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
                     cursor: 392
                   },
                   kind: :ordinary
                 }
               ],
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 624
               },
               kind: :ordinary
             } = Transfer.serialize_and_sign(transfer, keypair.secret_key)

      assert "fd927b1e4011589dac5bac64da739f352339de14bf9b21f2df83400639fd6721dc592a69cdd3ef66c051c76f69461a4d2d4747a8dd7917df617c57c979e48b0d00000001ffffffff0000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end

    test "verify" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")

      wallet = Wallet.create(keypair.public_key)

      params = [
        seqno: 1,
        value: 1,
        bounce: false,
        to: address,
        wallet_id: wallet.wallet_id,
        epoch_timeout: 1_672_315_426
      ]

      assert %Ton.Cell{
               data: %Ton.Bitstring{
                 length: 1023,
                 array: array,
                 cursor: 624
               }
             } =
               params
               |> Transfer.new()
               |> Transfer.serialize_and_sign(keypair.secret_key)

      assert "75ec5e3d41c37b8c33b84ca93da0b7641677095bb77549cd5557b2711d6b1964628721d1a6285584d35d4403b7c50f6117dbac71150b44b085a87c990c42af0e29a9a31763ad82220000000100030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" =
               array |> :binary.list_to_bin() |> Base.encode16(case: :lower)
    end
  end
end
