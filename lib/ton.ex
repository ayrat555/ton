defmodule Ton do
  @moduledoc """
  Documentation for `Ton`.
  """

  alias Salty.Sign.Ed25519
  alias Ton.Address
  alias Ton.KeyPair
  alias Ton.Wallet

  @pbkdf2_options %{
    alg: "sha512",
    iterations: 100_000,
    length: 64,
    format: true,
    salt: "TON default seed"
  }

  @doc """
  Generates a key pair from a mnemonic.

    ## Examples

    iex> Ton.mnemonic_to_keypair("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
    %Ton.KeyPair{
      secret_key: <<149, 222, 63, 223, 23, 72, 240, 224, 233, 177, 155, 16, 101,
        229, 182, 172, 23, 131, 54, 43, 195, 139, 217, 194, 100, 19, 252, 105, 68,
        30, 96, 95, 73, 245, 11, 185, 76, 95, 180, 99, 83, 74, 157, 13, 240, 216,
        227, 155, 203, 147, 16, 149, 137, 218, 246, 81, 151, 233, 21, 28, 55, 119,
        64, 47>>,
      public_key: <<73, 245, 11, 185, 76, 95, 180, 99, 83, 74, 157, 13, 240, 216,
        227, 155, 203, 147, 16, 149, 137, 218, 246, 81, 151, 233, 21, 28, 55, 119,
        64, 47>>
    }
  """
  @spec mnemonic_to_keypair(String.t(), String.t()) :: {binary(), binary()}
  def mnemonic_to_keypair(mnemonic, password \\ "") do
    {:ok, public_key, private_key} =
      mnemonic
      |> mnemonic_to_seed(password)
      |> Ed25519.seed_keypair()

    KeyPair.new(private_key, public_key)
  end

  @doc """
  Converts a mnemonic to a seed.

  ## Examples

      iex> Ton.mnemonic_to_seed("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
      # 95de3fdf1748f0e0e9b19b1065e5b6ac1783362bc38bd9c26413fc69441e605f
      <<149, 222, 63, 223, 23, 72, 240, 224, 233, 177, 155, 16, 101, 229, 182, 172, 23, 131, 54, 43, 195, 139, 217, 194, 100, 19, 252, 105, 68, 30, 96, 95>>
  """
  @spec mnemonic_to_seed(String.t(), String.t()) :: binary()
  def mnemonic_to_seed(mnemonic, password \\ "") do
    <<seed::binary-32, _::binary-32>> =
      mnemonic
      |> mnemonic_to_entropy(password)
      |> ExPBKDF2.pbkdf2(@pbkdf2_options)

    seed
  end

  @doc """
  Converts a mnemonic to an entropy.

  ## Examples

      iex> Ton.mnemonic_to_entropy("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
      # "1ab77da4f35581bd6f8efdcaef689ec180c6f77d214e4dd960f1619f6c40599f04798cb4e93e30edceeb02ab36f450df1c359e7b3395f13646134046cc6a7f3a"
      <<26, 183, 125, 164, 243, 85, 129, 189, 111, 142, 253, 202, 239, 104, 158, 193, 128, 198, 247, 125, 33, 78, 77, 217, 96, 241, 97, 159, 108, 64, 89, 159, 4, 121, 140, 180, 233, 62, 48, 237, 206, 235, 2, 171, 54, 244, 80, 223, 28, 53, 158, 123, 51, 149, 241, 54, 70, 19, 64, 70, 204, 106, 127, 58>>
  """
  @spec mnemonic_to_entropy(String.t(), String.t()) :: binary()
  def mnemonic_to_entropy(mnemonic, password \\ "") do
    :crypto.mac(:hmac, :sha512, mnemonic, password)
  end

  @doc """
  Initializes a `Wallet` struct from public_key, workchain and wallet_id

  ## Examples

    iex> keypair = Ton.mnemonic_to_keypair("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
    iex> %Ton.Wallet{initial_code: _, initial_data: _, workchain: 0, wallet_id: 698983191, public_key: <<73, 245, 11, 185, 76, 95, 180, 99, 83, 74, 157, 13, 240, 216, 227, 155, 203, 147, 16, 149, 137, 218, 246, 81, 151, 233, 21, 28, 55, 119, 64, 47>>} = Ton.create_wallet(keypair.public_key)
  """

  @spec create_wallet(binary(), integer(), integer()) :: Wallet.t()
  def create_wallet(public_key, workchain \\ 0, wallet_id \\ 698_983_191) do
    Wallet.create(public_key, workchain, wallet_id)
  end

  @doc """
  Parses and validates an address

  ## Examples

    iex> Ton.parse_address("UQCAIBANQeQX6UHmRgxHGR44oUL7VOQE9v4dxmla23KpjKIj")
    {:ok, %Ton.Address{test_only: false, bounceable: false, workchain: 0, hash: <<128, 32, 16, 13, 65, 228, 23, 233, 65, 230, 70, 12, 71, 25, 30, 56, 161, 66, 251, 84, 228, 4, 246, 254, 29, 198, 105, 90, 219, 114, 169, 140>>}}

    iex> Ton.parse_address("address")
    {:error, :invalid_base64}
  """
  @spec parse_address(binary()) :: {:ok, Address.t()} | {:error, atom()}
  def parse_address(address) do
    Address.parse(address)
  end

  @doc """
  Generates a friendly adress from a wallet struct

  ## Examples

    iex> keypair = Ton.mnemonic_to_keypair("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
    iex> wallet = Ton.create_wallet(keypair.public_key)
    iex> Ton.wallet_to_friendly_address(wallet)
    "EQAC824gsw8OZLoMV6_nr4nkxaEQFlbzoiHHOWIYY81eM5rQ"

    iex> keypair = Ton.mnemonic_to_keypair("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
    iex> wallet = Ton.create_wallet(keypair.public_key)
    iex> Ton.wallet_to_friendly_address(wallet, [url_safe: false, bounceable: false, test_only: true])
    "0QAC824gsw8OZLoMV6/nr4nkxaEQFlbzoiHHOWIYY81eM3yf"
  """
  @spec wallet_to_friendly_address(Wallet.t(), Keyword.t()) :: binary()
  def wallet_to_friendly_address(wallet, params \\ []) do
    Address.friendly_address(wallet, params)
  end
end
