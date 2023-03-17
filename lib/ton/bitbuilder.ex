defmodule Ton.BitBuilder do
  alias Ton.NewBitstring

  import Bitwise

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          array: [non_neg_integer()]
        }

  defstruct [
    :length,
    :array
  ]

  @spec new(non_neg_integer()) :: t()
  def new(size) do
    length = Float.ceil(size / 8.0) |> trunc()
    array = List.duplicate(0, length)

    %__MODULE__{length: size, array: array}
  end

  @spec write_bit(t(), boolean() | integer()) :: t()
  def write_bit(bitbuilder, value) do
    n = bitbuilder.length

    if n > bitbuilder.buffer.length * 8 do
      raise "BitBuilder overflow"
    end

    set_bit? =
      if is_boolean(value) do
        value
      else
        value > 0
      end

    bitbuilder =
      if set_bit? do
        idx = div(n, 8) ||| 0
        byte = Enum.at(bitbuilder.array, idx)

        set_value(bitbuilder, idx, byte ||| 1 <<< (7 - rem(n, 8)))
      else
        bitbuilder
      end

    add_length(bitbuilder, 1)
  end

  @spec write_bits(BitBuilder.t(), Bitstring.t()) :: BitBuilder.t()
  def write_bits(bitbuilder, src) do
    Enum.reduce(0..(src.length - 1), bitbuilder, fn idx ->
      bit = NewBitstring.at(src, idx)

      write_bit(bitbuilder, bit)
    end)
  end

  @spec write_buffer(t(), [non_neg_integer()]) :: BitBuilder.t()
  def write_buffer(bitbuilder, src) do
    byte_size = byte_size(src)

    if rem(bitbuilder.length, 8) == 0 do
      if bitbuilder.length + byte_size * 8 > bitbuilder.buffer.length * 8 do
        raise "BitBuilder overflow"
      end

      add_length(%{bitbuilder | array: bitbuilder.array ++ src}, byte_size * 8)
    else
      Enum.reduce(0..(byte_size - 1), bitbuilder, fn idx ->
        value = Enum.at(src, idx)

        write_uint(bitbuilder, value, 8)
      end)
    end
  end

  @spec write_uint(t(), non_neg_integer(), non_neg_integer()) :: t()
  def write_uint(bitbuilder, value, bits) do
    cond do
      bits == 8 && rem(bitbuilder.length, 8) == 0 ->
        if value < 0 || value > 255 do
          raise "value is out of range for #{bits} bits. Got #{value}"
        end

        byte_idx = div(bitbuilder.length, 8)

        bitbuilder
        |> set_value(byte_idx, value)
        |> add_length(8)

      bits == 16 && rem(bitbuilder.length, 8) == 0 ->
        if value < 0 || value > 65_536 do
          raise "value is out of range for #{bits} bits. Got #{value}"
        end

        byte_idx = div(bitbuilder.length, 8)

        bitbuilder
        |> set_value(byte_idx, value >>> 8)
        |> set_value(byte_idx + 1, value &&& 0xFF)
        |> add_length(16)

      bits < 0 ->
        raise "Invalid bit length. Got #{bits}"

      bits == 0 ->
        if value != 0 do
          raise "value is not zero for #{bits} bits. Got #{value}"
        end

        bitbuilder

      true ->
        if value < 0 || value >= 1 <<< bits do
          raise "bitLength is too small for a value #{value}. Got #{bits}"
        end

        bits_value = number_to_bits(value)

        Enum.reduce(0..(bits - 1), bitbuilder, fn i ->
          off = bits - i - 1

          if off < bitbuilder.length do
            bit = Enum.at(bits_value, off)

            write_bit(bitbuilder, bit)
          else
            write_bit(bitbuilder, false)
          end
        end)
    end
  end

  defp number_to_bits(current_number, acc \\ [])

  defp number_to_bits(current_number, acc) when current_number <= 0, do: Enum.reverse(acc)

  defp number_to_bits(current_number, acc) do
    current_value = rem(current_number, 2)

    number_to_bits(div(current_number, 2), [current_value | acc])
  end

  defp set_value(bitbuilder, idx, value) do
    array = List.replace_at(bitbuilder.array, idx, value)

    %{bitbuilder | array: array}
  end

  defp add_length(bitbuilder, add_length) do
    %{bitbuilder | length: bitbuilder.length + add_length}
  end
end
