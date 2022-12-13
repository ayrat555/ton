defmodule Ton.WalletTest do
  use ExUnit.Case

  alias Ton.Wallet

  describe "create/3" do
    test "creates a wallet struct" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )
        |> IO.inspect()

      assert %{initial_data: initial_data} = Wallet.create(0, keypair.public_key)
      Base.encode16(:binary.list_to_bin(initial_data.data.array), case: :lower) |> IO.inspect()
    end
  end
end
