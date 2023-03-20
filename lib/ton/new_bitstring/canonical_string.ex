defmodule Ton.NewBitstring.CanonicalString do
  alias Ton.BitBuilder

  def padded_buffer(bitstring) do
    complete_byte_bits = (Float.ceil(bitstring.length / 8.0) |> trunc()) * 8

    bitbuilder =
      complete_byte_bits
      |> BitBuilder.new()
      |> BitBuilder.write_bits(bitstring)

    padding = complete_byte_bits - bitstring.length

    bitbuilder =
      Enum.reduce(0..(padding - 1), bitbuilder, fn bit, acc ->
        if bit == 0 do
          BitBuilder.write_bit(bitbuilder, 1)
        else
          BitBuilder.write_bit(bitbuilder, 0)
        end
      end)

    bitbuilder.array
  end
end
