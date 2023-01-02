defmodule ExternalMessageTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.Cell
  alias Ton.CommonMessageInfo
  alias Ton.ExternalMessage
  alias Ton.Transfer
  alias Ton.Wallet

  describe "serialize/2" do
    test "serializes an external message (already deployed contract)" do
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
          wallet_id: wallet.wallet_id,
          epoch_timeout: 1_672_315_426
        )
        |> Transfer.serialize_and_sign(keypair.secret_key)

      common_message_info = CommonMessageInfo.new(nil, transfer)

      assert "74cf905a7d5d7e66c11efbcf8128ced5abfb14a7405c6e9be097fc7af3ec3528" ==
               wallet
               |> ExternalMessage.new(common_message_info)
               |> ExternalMessage.serialize()
               |> Cell.hash()
               |> Base.encode16(case: :lower)
    end

    # test "serializes an external message (a new contract)" do
    #   keypair =
    #     Ton.mnemonic_to_keypair(
    #       "house about about about about about about about about about about about about about about about about about about about about about about about"
    #     )

    #   wallet = Wallet.create(0, keypair.public_key)
    #   {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")

    #   transfer =
    #     Transfer.new(
    #       seqno: 0,
    #       value: 1,
    #       bounce: false,
    #       to: address,
    #       wallet_id: wallet.wallet_id,
    #       epoch_timeout: 1_672_315_426
    #     )
    #     |> Transfer.serialize_and_sign(keypair.secret_key)

    #   common_message_info = CommonMessageInfo.new(wallet, transfer)

    #   assert "74cf905a7d5d7e66c11efbcf8128ced5abfb14a7405c6e9be097fc7af3ec3528" ==
    #            wallet
    #            |> ExternalMessage.new(common_message_info)
    #            |> ExternalMessage.serialize()
    #            |> Cell.hash()
    #            |> Base.encode16(case: :lower)
    # end
  end
end
