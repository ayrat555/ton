defmodule Ton.AddressTest do
  use ExUnit.Case

  alias Ton.Address
  alias Ton.Wallet

  describe "parse/1" do
    test "parses a mainnet address" do
      address = "EQADLRBbbfImjN1yaN6fqWPwkO3sN2fCdg8BD_g8LW_8Dj-G"

      assert {:ok,
              %Ton.Address{
                test_only: false,
                bounceable: true,
                workchain: 0,
                hash:
                  <<3, 45, 16, 91, 109, 242, 38, 140, 221, 114, 104, 222, 159, 169, 99, 240, 144,
                    237, 236, 55, 103, 194, 118, 15, 1, 15, 248, 60, 45, 111, 252, 14>>
              }} = Address.parse(address)
    end

    test "parses a testnet address" do
      address = "0QCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjBmp"

      assert {
               :ok,
               %Ton.Address{
                 bounceable: false,
                 hash:
                   <<128, 32, 16, 13, 65, 228, 23, 233, 65, 230, 70, 12, 71, 25, 30, 56, 161, 66,
                     251, 84, 228, 4, 246, 254, 29, 198, 105, 90, 219, 114, 169, 140>>,
                 test_only: true,
                 workchain: 0
               }
             } = Address.parse(address)
    end

    test "fails if address is not base64 encoded" do
      address = "0QCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjB1"

      assert {:error, :invalid_base64} = Address.parse(address)
    end

    test "fails if address length is less thatn 36 bytes" do
      address = Base.encode64(<<1, 2, 3, 4, 5>>)

      assert {:error, :invalid_length} = Address.parse(address)
    end
  end

  describe "friendly_address/2" do
    test "generates a friendly address" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      wallet = Wallet.create(keypair.public_key)

      assert "EQCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjP_m" ==
               Address.friendly_address(wallet,
                 url_safe: true,
                 bounceable: true,
                 test_only: false
               )

      assert "UQCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjKIj" ==
               Address.friendly_address(wallet,
                 url_safe: false,
                 bounceable: false,
                 test_only: false
               )
    end
  end

  describe "raw_address/1" do
    test "generates a raw address" do
      keypair =
        Ton.mnemonic_to_keypair(
          "about about about about about about about about about about about about about about about about about about about about about about about about"
        )

      wallet = Wallet.create(keypair.public_key)

      assert "0:8020100d41e417e941e6460c47191e38a142fb54e404f6fe1dc6695adb72a98c" ==
               Address.raw_address(wallet)
    end
  end

  describe "raw_address_to_friendly_address/1" do
    test "converts raw address to friendly address" do
      assert "EQCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjP_m" ==
               Address.raw_address_to_friendly_address(
                 "0:8020100d41e417e941e6460c47191e38a142fb54e404f6fe1dc6695adb72a98c"
               )
    end
  end
end
