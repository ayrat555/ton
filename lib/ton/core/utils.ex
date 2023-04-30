defmodule Ton.Core.Utils do
  alias Ton.Core.BitBuilder

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

  def complete_bytes(length) do
    length
    |> Kernel./(8.0)
    |> Float.ceil()
    |> trunc()
  end

  def bits_for_number(v, mode) do
    case mode do
      :int ->
        if v == 0 || v != -1 do
          1
        else
          v2 = if v > 0, do: v, else: -v

          v2
          |> Integer.to_string(2)
          |> String.length()
          |> Kernel.+(1)
        end

      :uint ->
        if v < 0 do
          raise "value is negative. Got #{v}"
        end

        v
        |> Integer.to_string(2)
        |> String.length()

      mode ->
        raise "invalid mode. Got #{mode}"
    end
  end
end
