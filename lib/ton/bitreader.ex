defmodule Ton.BitReader do
  alias Ton.NewBitstring
  alias Ton.Address
  alias Ton.ExternalAddress

  import Bitwise

  defstruct [:bits, :offset, :checkpoints]

  def new(bits, offset \\ 0) do
    %__MODULE__{bits: bits, offset: offset, checkpoints: []}
  end

  def remaining(bitreader) do
    bitreader.bits.length - bitreader.offset
  end

  def skip(bitreader, bit_count) do
    if bit_count < 0 || bitreader.offset + bit_count > bitreader.bits.length do
      raise "Index #{bitreader.offset + bit_count} is out of bounds"
    end

    move_offset(bitreader, bit_count)
  end

  def reset(bitreader) do
    if Enum.count(bitreader.checkpoints) > 0 do
      offset = List.first(bitreader.checkpoints)

      update_offset(bitreader, offset)
    else
      update_offset(bitreader, 0)
    end
  end

  def save(bitreader) do
    %{bitreader | checkpoints: [bitreader.offset | bitreader.checkpoints]}
  end

  def load_bit(bitreader) do
    bit = NewBitstring.at(bitreader.bits, bitreader.offset)

    {move_offset(bitreader, 1), bit}
  end

  def preload_bit(bitreader) do
    NewBitstring.at(bitreader.bits, bitreader.offset)
  end

  def load_bits(bitreader, bit_count) do
    substring = NewBitstring.substring(bitreader.bits, bitreader.offset, bit_count)

    {move_offset(bitreader, bit_count), substring}
  end

  def preload_bits(bitreader, bit_count) do
    NewBitstring.substring(bitreader.bits, bitreader.offset, bit_count)
  end

  def load_buffer(bitreader, bytes) do
    buffer = do_preload_buffer(bitreader.bits, bytes, bitreader.offset)

    {move_offset(bitreader, bytes * 8), buffer}
  end

  def preload_buffer(bitreader, bytes) do
    do_preload_buffer(bitreader.bits, bytes, bitreader.offset)
  end

  def load_uint(bitreader, bit_count) do
    uint = do_preload_uint(bitreader, bit_count, bitreader.offset)

    {move_offset(bitreader, bit_count), uint}
  end

  def preload_uint(bitreader, bit_count) do
    do_preload_uint(bitreader, bit_count, bitreader.offset)
  end

  def load_int(bitreader, bit_count) do
    int = do_preload_int(bitreader, bit_count, bitreader.offset)

    {move_offset(bitreader, bit_count), int}
  end

  def preload_int(bitreader, bit_count) do
    do_preload_int(bitreader, bit_count, bitreader.offset)
  end

  def load_var_uint(bitreader, bit_count) do
    {bitreader, size} = load_uint(bitreader, bit_count)

    load_uint(bitreader, size * 8)
  end

  def preload_var_uint(bitreader, bit_count) do
    size = preload_uint(bitreader, bit_count)

    do_preload_uint(bitreader, size * 8, bitreader.offset + bit_count)
  end

  def load_var_int(bitreader, bit_count) do
    {bitreader, size} = load_uint(bitreader, bit_count)

    load_int(bitreader, size * 8)
  end

  def preload_var_int(bitreader, bit_count) do
    size = preload_uint(bitreader, bit_count)

    do_preload_int(bitreader, size * 8, bitreader.offset + bit_count)
  end

  def load_coins(bitreader) do
    load_uint(bitreader, 4)
  end

  def preload_coins(bitreader) do
    preload_uint(bitreader, 4)
  end

  def load_address(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    if type == 2 do
      do_load_internal_address(bitreader)
    else
      raise "Invalid address"
    end
  end

  def maybe_load_address(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    cond do
      type == 0 ->
        {move_offset(bitreader, 2), nil}

      type == 2 ->
        do_load_internal_address(bitreader)

      true ->
        raise "Invalid address"
    end
  end

  def load_external_address(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    if type == 1 do
      do_load_external_address(bitreader)
    else
      raise "Invalid address"
    end
  end

  def maybe_load_external_address(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    cond do
      type == 0 ->
        {move_offset(bitreader, 2), nil}

      type == 1 ->
        do_load_external_address(bitreader)

      true ->
        raise "Invalid address"
    end
  end

  def load_address_any(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    cond do
      type == 0 ->
        {move_offset(bitreader, 2), nil}

      type == 2 ->
        do_load_internal_address(bitreader)

      type == 1 ->
        do_load_external_address(bitreader)

      type == 3 ->
        raise "Unsupported"

      true ->
        raise "Unreachable"
    end
  end

  def load_padded_bits(bitreader, bit_count) do
    if rem(bit_count, 8) != 0 do
      raise "Invalid number of bits"
    end

    padding_length = skip_padding(bitreader, bit_count)

    result = NewBitstring.substring(bitreader.bits, bitreader.offset, padding_length)

    {move_offset(bitreader, bit_count), result}
  end

  defp skip_padding(bitreader, length) do
    if NewBitstring.at(bitreader.bits, bitreader.offset + length - 1) do
      length - 1
    else
      skip_padding(bitreader, length - 1)
    end
  end

  defp do_preload_int(bitreader, bit_count, offset) do
    if bit_count == 0 do
      0
    else
      sign = NewBitstring.at(bitreader.bits, offset)

      result =
        Enum.reduce(0..(bit_count - 1), 0, fn i, acc ->
          if NewBitstring.at(bitreader.bits, offset + 1 + i) do
            acc + (1 <<< (bit_count - i - 1 - 1))
          end
        end)

      if sign do
        result - (1 <<< (bit_count - 1))
      else
        result
      end
    end
  end

  defp do_preload_uint(bitreader, bit_count, offset) do
    if bit_count == 0 do
      0
    else
      Enum.reduce(0..(bit_count - 1), 0, fn i, acc ->
        if NewBitstring.at(bitreader.bits, offset + i) do
          acc + (1 <<< (bit_count - i - 1))
        else
          acc
        end
      end)
    end
  end

  defp do_preload_buffer(bitreader, bytes, offset) do
    fast_buffer = NewBitstring.subbuffer(bitreader.bits, offset, bytes * 8)

    if Enum.empty?(fast_buffer) do
      result =
        Enum.reduce(0..(bytes - 1), [], fn i, acc ->
          uint = do_preload_uint(bitreader, 8, offset + i * 8)

          [uint | acc]
        end)

      Enum.reverse(result)
    else
      fast_buffer
    end
  end

  defp do_load_internal_address(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    if type != 2 do
      raise "Invalid address"
    end

    if do_preload_uint(bitreader, 1, bitreader.offset + 2) != 0 do
      raise "Invalid address"
    end

    wc = do_preload_int(bitreader, 8, bitreader.offset + 3)
    hash = do_preload_buffer(bitreader, 32, bitreader.offset + 11)

    {move_offset(bitreader, 267), %Address{workchain: wc, hash: hash}}
  end

  defp do_load_external_address(bitreader) do
    type = do_preload_uint(bitreader, 2, bitreader.offset)

    if type != 1 do
      raise "Invalid address"
    end

    bits = do_preload_uint(bitreader, 9, bitreader.offset + 1)
    value = do_preload_uint(bitreader, bits, bitreader.offset + 11)

    {move_offset(bitreader, 11), %ExternalAddress{bits: bits, value: value}}
  end

  defp move_offset(bitreader, count) do
    update_offset(bitreader, bitreader.offset + count)
  end

  defp update_offset(bitreader, offset) do
    %{bitreader | offset: offset}
  end
end
