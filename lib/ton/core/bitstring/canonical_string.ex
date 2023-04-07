defmodule Ton.Core.Bitstring.CanonicalString do
  alias Ton.Core.BitBuilder
  alias Ton.Core.Bitstring

  def to_string(%Bitstring{length: 0}), do: ""

  def to_string(bitstring) do
    padded_buffer = padded_buffer(bitstring)

    if rem(bitstring.length, 4) == 0 do
      result =
        padded_buffer
        |> Enum.slice(0, complete_bytes(bitstring.length))
        |> :binary.list_to_bin()
        |> Base.encode16(case: :upper)

      if rem(bitstring.length, 8) == 0 do
        result
      else
        length = String.length(result)

        String.slice(result, 0, length - 1)
      end
    else
      result =
        padded_buffer
        |> :binary.list_to_bin()
        |> Base.encode16(case: :upper)

      if rem(bitstring.length, 8) <= 4 do
        length = String.length(result)

        String.slice(result, 0, length - 1) <> "_"
      else
        result <> "_"
      end
    end
  end

  def padded_buffer(bitstring) do
    complete_byte_bits = complete_bytes(bitstring.length) * 8

    bitbuilder =
      complete_byte_bits
      |> BitBuilder.new()
      |> BitBuilder.write_bits(bitstring)

    padding = complete_byte_bits - bitstring.length

    bitbuilder =
      if padding > 0 do
        Enum.reduce(0..(padding - 1), bitbuilder, fn bit, acc ->
          if bit == 0 do
            BitBuilder.write_bit(acc, 1)
          else
            BitBuilder.write_bit(acc, 0)
          end
        end)
      else
        bitbuilder
      end

    bitbuilder.array
  end

  defp complete_bytes(length) do
    length
    |> Kernel./(8.0)
    |> Float.ceil()
    |> trunc()
  end
end
