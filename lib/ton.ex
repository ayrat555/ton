defmodule Ton do
  @moduledoc """
  Documentation for `Ton`.
  """

  # @pbkdf2_options %{alg: "sha512", iterations: 100_000, length: 32, format: true, salt: }

  # @doc """
  # Hello world.

  # ## Examples

  #     iex> Ton.hello()
  #     :world

  # """
  # def mnemonic_to_seed(mnemonic) do
  # end

  @doc """
  Converts mnemonic to entropy.

  ## Examples

      iex> Ton.mnemonic_to_entropy("rail sound peasant garment bounce trigger true abuse arctic gravity ribbon ocean absurd okay blue remove neck cash reflect sleep hen portion gossip arrow")
      # "1ab77da4f35581bd6f8efdcaef689ec180c6f77d214e4dd960f1619f6c40599f04798cb4e93e30edceeb02ab36f450df1c359e7b3395f13646134046cc6a7f3a"
      <<26, 183, 125, 164, 243, 85, 129, 189, 111, 142, 253, 202, 239, 104, 158, 193, 128, 198, 247, 125, 33, 78, 77, 217, 96, 241, 97, 159, 108, 64, 89, 159, 4, 121, 140, 180, 233, 62, 48, 237, 206, 235, 2, 171, 54, 244, 80, 223, 28, 53, 158, 123, 51, 149, 241, 54, 70, 19, 64, 70, 204, 106, 127, 58>>
  """
  @spec mnemonic_to_entropy(String.t(), String.t()) :: binary()
  def mnemonic_to_entropy(mnemonic, password \\ "") do
    :crypto.mac(:hmac, :sha512, mnemonic, password)
  end
end
