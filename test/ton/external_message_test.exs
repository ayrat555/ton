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
          wallet_id: wallet.wallet_id
        )
        |> Transfer.serialize_and_sign(keypair.secret_key)

      common_message_info = CommonMessageInfo.new(nil, transfer)

      cell =
        wallet
        |> ExternalMessage.new(common_message_info)
        |> ExternalMessage.serialize()

      # assert "74cf905a7d5d7e66c11efbcf8128ced5abfb14a7405c6e9be097fc7af3ec3528" ==
      #          cell
      #          |> Cell.hash()
      #          |> Base.encode16(case: :lower)

      assert "b5ee9c724101020100a70001e188010040201a83c82fd283cc8c188e323c714285f6a9c809edfc3b8cd2b5b6e5531803af62f1ea0e1bdc619dc26549ed05bb20b3b84addbbaa4e6aaabd9388eb58cb2314390e8d3142ac269aea201dbe287b08bedd6388a85a25842d43e4c8621578714d4d18bb1d6c111000000008001c01006242000392875059b1ac00bd98d8fd97394d50d33bccb431fa5413b77b28426795860d8808000000000000000000000000003ebd8a12" ==
               cell |> Cell.serialize(has_idx: false) |> Base.encode16(case: :lower)
    end

    test "serializes an external message (a new contract)" do
      keypair =
        Ton.mnemonic_to_keypair(
          "house about about about about about about about about about about about about about about about about about about about about about about about"
        )

      wallet = Wallet.create(0, keypair.public_key)
      {:ok, address} = Address.parse("EQAHJQ6gs2NYAXsxsfsucpqhpneZaGP0qCdu9lCEzysMGzst")

      transfer =
        Transfer.new(
          seqno: 0,
          value: 1,
          bounce: false,
          to: address,
          wallet_id: wallet.wallet_id,
          epoch_timeout: 1_672_315_426
        )
        |> Transfer.serialize_and_sign(keypair.secret_key)

      common_message_info = CommonMessageInfo.new(wallet, transfer)

      cell =
        wallet
        |> ExternalMessage.new(common_message_info)
        |> ExternalMessage.serialize()

      assert "0d9d32510e81d23e0f05cf88e2b959d3e3db724e18be557192b91c6566afdcd5" ==
               cell
               |> Cell.hash()
               |> Base.encode16(case: :lower)

      assert "b5ee9c72410217010003a90003e38801e6c96e7c709d192d450f1796185e5c2e591df3db8c5070940b5351910629d270119787b3dc7a7ad56138376a83c8b7a9ef00b9a67713f24fa0d439ab1e91adf53146c11abacc1d94c0a3c11935aba10fba442ca5443c6e63a1c034182f6effcc8145353462ffffffffe0000000000070030201006242000392875059b1ac00bd98d8fd97394d50d33bccb431fa5413b77b28426795860d88080000000000000000000000000000510000000029a9a317c6e8324ddabbfc320ed4374a04345151886ecc8e8bc1141298a766b7b7a02af4400114ff00f4a413f4bcf2c80b040201200a0504f8f28308d71820d31fd31fd31f02f823bbf264ed44d0d31fd31fd3fff404d15143baf2a15151baf2a205f901541064f910f2a3f80024a4c8cb1f5240cb1f5230cbff5210f400c9ed54f80f01d30721c0009f6c519320d74a96d307d402fb00e830e021c001e30021c002e30001c0039130e30d03a4c8cb1f12cb1fcbff09080706000af400c9ed54006c810108d718fa00d33f305224810108f459f2a782106473747270748018c8cb05cb025005cf165003fa0213cb6acb1f12cb3fc973fb000070810108d718fa00d33fc8542047810108f451f2a782106e6f746570748018c8cb05cb025006cf165004fa0214cb6a12cb1fcb3fc973fb0002006ed207fa00d4d422f90005c8ca0715cbffc9d077748018c8cb05cb0222cf165005fa0214cb6b12ccccc973fb00c84014810108f451f2a702020148140b0201200d0c0059bd242b6f6a2684080a06b90fa0218470d4080847a4937d29910ce6903e9ff9837812801b7810148987159f31840201200f0e0011b8c97ed44d0d70b1f8020158131002012012110019af1df6a26840106b90eb858fc00019adce76a26840206b90eb85ffc0003db29dfb513420405035c87d010c00b23281f2fff274006040423d029be84c6002e6d001d0d3032171b0925f04e022d749c120925f04e002d31f218210706c7567bd22821064737472bdb0925f05e003fa403020fa4401c8ca07cbffc9d0ed44d0810140d721f404305c810108f40a6fa131b3925f07e005d33fc8258210706c7567ba923830e30d03821064737472ba925f06e30d1615008a5004810108f45930ed44d0810140d720c801cf16f400c9ed540172b08e23821064737472831eb17080185005cb055003cf1623fa0213cb6acb1fcb3fc98040fb00925f03e2007801fa00f40430f8276f2230500aa121bef2e0508210706c7567831eb17080185004cb0526cf1658fa0219f400cb6917cb1f5260cb3f20c98040fb0006a60ba63e" ==
               cell |> Cell.serialize(has_idx: false) |> Base.encode16(case: :lower)
    end
  end
end
