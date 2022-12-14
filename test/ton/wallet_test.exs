defmodule Ton.WalletTest do
  use ExUnit.Case

  alias Ton.Wallet

  describe "create/3" do
    test "creates a wallet struct" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      assert %{initial_data: initial_data} = Wallet.create(0, keypair.public_key)

      assert "0000000029a9a317da8c62f44c30dfbb75b1e44b780aca8a309533d1e1579484e56eb20413cd01da00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" ==
               Base.encode16(:binary.list_to_bin(initial_data.data.array), case: :lower)
    end
  end
end
