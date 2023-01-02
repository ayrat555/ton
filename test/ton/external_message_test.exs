defmodule ExternalMessageTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.Cell
  alias Ton.CommonMessageInfo
  alias Ton.ExternalMessage
  alias Ton.Transfer
  alias Ton.Wallet

  describe "serialize/2" do
    test "serializes an external message" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      wallet = Wallet.create(0, keypair.public_key)
      {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")

      transfer =
        Transfer.new(
          seqno: 1,
          value: 1,
          bounce: false,
          to: address,
          wallet_id: wallet.wallet_id
        )
        |> Transfer.serialize_and_sign(keypair.secret_key)

      common_message_info = CommonMessageInfo.new(wallet, transfer)

      address
      |> ExternalMessage.new(common_message_info)
      |> ExternalMessage.serialize()
      |> Cell.hash()
      |> IO.inspect()
    end
  end
end
