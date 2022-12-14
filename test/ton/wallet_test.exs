defmodule Ton.WalletTest do
  use ExUnit.Case

  alias Ton.Wallet

  setup_all do
    keypair =
      Ton.mnemonic_to_keypair(
        "about about about about about about about about about about about about about about about about about about about about about about about about"
      )

    {:ok, %{keypair: keypair}}
  end

  describe "create/3" do
    test "creates a wallet struct", %{keypair: keypair} do
      assert %Ton.Wallet{
               initial_data:
                 %Ton.Cell{
                   refs: [],
                   data: %Ton.Bitstring{
                     length: 1023,
                     array: _,
                     cursor: 321
                   },
                   kind: :ordinary
                 } = initial_data,
               workchain: 0,
               wallet_id: 698_983_191,
               public_key:
                 <<218, 140, 98, 244, 76, 48, 223, 187, 117, 177, 228, 75, 120, 10, 202, 138, 48,
                   149, 51, 209, 225, 87, 148, 132, 229, 110, 178, 4, 19, 205, 1, 218>>
             } = Wallet.create(keypair.public_key)

      assert "0000000029a9a317da8c62f44c30dfbb75b1e44b780aca8a309533d1e1579484e56eb20413cd01da00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" ==
               Base.encode16(:binary.list_to_bin(initial_data.data.array), case: :lower)
    end
  end

  describe "state_init_cell/1" do
    test "creates state init cell from wallet", %{keypair: keypair} do
      wallet = Wallet.create(keypair.public_key)

      assert cell = Wallet.state_init_cell(wallet)

      assert <<48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0>> = :binary.list_to_bin(cell.data.array)
    end
  end

  describe "hash/1" do
    test "calculates wallet hash", %{keypair: keypair} do
      wallet = Wallet.create(keypair.public_key)

      assert "8020100d41e417e941e6460c47191e38a142fb54e404f6fe1dc6695adb72a98c" =
               Wallet.hash(wallet) |> Base.encode16(case: :lower)
    end
  end
end
