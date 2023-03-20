defmodule Ton.BitBuilder do
  import Bitwise

  alias Ton.Address
  alias Ton.ExternalAddress
  alias Ton.NewBitstring

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          array: [non_neg_integer()]
        }

  defstruct [
    :length,
    :array
  ]

  @spec new(non_neg_integer()) :: t()
  def new(size \\ 1023) do
    length = Float.ceil(size / 8.0) |> trunc()
    array = List.duplicate(0, length)

    %__MODULE__{length: 0, array: array}
  end

  @spec write_bit(t(), boolean() | integer()) :: t()
  def write_bit(bitbuilder, value) do
    n = bitbuilder.length

    if n > Enum.count(bitbuilder.array) * 8 do
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
        v_bits = 1 <<< bits

        if value < 0 || value >= v_bits do
          raise "bitLength is too small for a value #{value}. Got #{bits}"
        end

        bits_value = number_to_bits(value)

        Enum.reduce(0..(bits - 1), bitbuilder, fn i, bitbuilder ->
          IO.inspect(bitbuilder)
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

  @spec write_int(t(), integer(), non_neg_integer()) :: t()
  def write_int(bitbuilder, value, bits) do
    if bits < 0 do
      raise "invalid bit length. Got #{bits}"
    end

    cond do
      bits == 0 ->
        if value != 0 do
          raise "value is not zero for #{bits} bits. Got #{value}"
        end

        bitbuilder

      bits == 1 ->
        if value != -1 && value != 0 do
          raise "value is not zero or -1 for #{bits} bits. Got #{value}"
        end

        write_bit(bitbuilder, value == -1)

      true ->
        v_bits = 1 <<< (bits - 1)

        if value < -v_bits || value >= v_bits do
          raise "value is out of range for #{bits} bits. Got 3{value}"
        end

        {bitbuilder, value} =
          if value < 0 do
            bitbuilder = write_bit(bitbuilder, true)

            {bitbuilder, v_bits + value}
          else
            bitbuilder = write_bit(bitbuilder, false)

            {bitbuilder, value}
          end

        write_uint(bitbuilder, value, bits - 1)
    end
  end

  @spec write_var_uint(t(), non_neg_integer(), non_neg_integer()) :: t()
  def write_var_uint(bitbuilder, value, bits) do
    if bits < 0 do
      raise "invalid bit length. Got #{bits}"
    end

    cond do
      value < 0 ->
        raise "value is negative. Got #{value}"

      value == 0 ->
        write_uint(bitbuilder, 0, bits)

      true ->
        size_bytes =
          value
          |> Integer.to_string(2)
          |> String.length()
          |> Kernel./(8.0)
          |> Float.ceil()
          |> trunc()

        size_bits = size_bytes * 8

        bitbuilder
        |> write_uint(size_bytes, bits)
        |> write_uint(value, size_bits)
    end
  end

  @spec write_var_int(t(), integer(), non_neg_integer()) :: t()
  def write_var_int(bitbuilder, value, bits) do
    if bits < 0 do
      raise "invalid bit length. Got #{bits}"
    end

    if value == 0 do
      write_uint(bitbuilder, 0, bits)
    else
      abs_value = if value > 0, do: value, else: -value

      size_bytes =
        abs_value
        |> Integer.to_string(2)
        |> String.length()
        |> Kernel./(8.0)
        |> Float.ceil()
        |> trunc()
        |> Kernel.+(1)

      size_bits = size_bytes * 8

      bitbuilder
      |> write_uint(size_bytes, bits)
      |> write_int(value, size_bits)
    end
  end

  @spec write_coins(t(), integer()) :: t()
  def write_coins(bitbuilder, amount) do
    write_var_uint(bitbuilder, amount, 4)
  end

  @spec write_address(t(), Address.t() | ExternalAddress.t()) :: t()
  def write_address(bitbuilder, address) do
    case address do
      nil ->
        write_uint(bitbuilder, 0, 2)

      %Address{workchain: workchain, hash: hash} ->
        hash_array = :binary.bin_to_list(hash)

        bitbuilder
        |> write_uint(2, 2)
        |> write_uint(0, 1)
        |> write_int(workchain, 8)
        |> write_buffer(hash_array)

      %ExternalAddress{value: value, bits: bits} ->
        bitbuilder
        |> write_uint(1, 2)
        |> write_uint(bits, 9)
        |> write_uint(value, bits)

      _ ->
        raise "Invalid address. Got #{address}"
    end
  end

  @spec build(t()) :: NewBitstring.t()
  def build(bitbuilder) do
    NewBitstring.new(bitbuilder.array, 0, bitbuilder.length)
  end

  defp number_to_bits(current_number, acc \\ [])

  defp number_to_bits(current_number, acc) when current_number <= 0, do: Enum.reverse(acc)

  defp number_to_bits(current_number, acc) do
    current_value = rem(current_number, 2) == 1

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
