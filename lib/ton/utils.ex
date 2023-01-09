defmodule Ton.Utils do
  @moduledoc """
  Various utility functions
  """

  @spec read_n_bytes_uint(binary(), non_neg_integer()) :: {non_neg_integer(), binary()}
  def read_n_bytes_uint(binary_data, n) do
    <<prefix::binary-size(n), tail::binary>> = binary_data

    result =
      prefix
      |> :binary.bin_to_list()
      |> Enum.reduce(0, fn byte, acc ->
        acc * 256 + byte
      end)

    {result, tail}
  end

  @spec sha256(binary()) :: binary()
  def sha256(binary_data) do
    :crypto.hash(:sha256, binary_data)
  end

  @spec sign(binary(), binary()) :: binary()
  def sign(data, private_key) do
    {:ok, signature} = Cafezinho.sign(data, private_key)

    signature
  end
end
