defmodule Ton.Utils do
  import Bitwise

  @poly 0x82F63B78

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

  def crc32c(binary_data) do
    crc = Ton.Bitwise.bixor(0, 0xFFFFFFFF)
    byte_list = :binary.bin_to_list(binary_data)

    crc =
      Enum.reduce(byte_list, crc, fn byte, acc ->
        acc = Ton.Bitwise.bixor(acc, byte)

        Enum.reduce(1..8, acc, fn _idx, nested_acc ->
          if (nested_acc &&& 1) == 0 do
            bxor(nested_acc >>> 1, @poly)
          else
            nested_acc >>> 1
          end
        end)
      end)

    crc = Ton.Bitwise.bixor(crc, 0xFFFFFFFF)

    :binary.encode_unsigned(crc, :little)
  end
end
