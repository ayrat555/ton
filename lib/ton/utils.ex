defmodule Ton.Utils do
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

  def sha256(binary_data) do
    :sha256
    |> :crypto.hash(binary_data)
  end
end
