defmodule Ton.Bitstring do
  import Bitwise

  defstruct [
    :length,
    :array,
    :cursor
  ]

  def new(length \\ 1023) do
    size = Float.ceil(length / 8.0) |> trunc()
    array = List.duplicate(0, size)

    %__MODULE__{
      length: length,
      array: array,
      cursor: 0
    }
  end

  def write_binary(bitstring, data) do
    data
    |> :binary.bin_to_list()
    |> Enum.reduce(bitstring, fn byte, acc ->
      write_uint8(acc, byte)
    end)
  end

  def write_uint8(bitstring, value) do
    write_uint(bitstring, value, 8)
  end

  def write_uint(bitstring, value, bit_length) do
    str_value = Integer.to_string(value, 2)

    cond do
      bit_length == 0 and value == 0 ->
        bitstring

      String.length(str_value) > bit_length ->
        raise "bitLength is too small for a value #{value}. Got #{bit_length}, expected >= #{String.length(str_value)}"

      true ->
        str_value
        |> pad(bit_length)
        |> String.graphemes()
        |> Enum.reduce(bitstring, fn bit_char, acc ->
          write_bit(acc, bit_char == "1")
        end)
    end
  end

  def write_bit(%__MODULE__{cursor: cursor} = bitstring, value)
      when is_boolean(value) do
    bitstring =
      if value do
        on_bit(bitstring, cursor)
      else
        off_bit(bitstring, cursor)
      end

    %{bitstring | cursor: cursor + 1}
  end

  def write_bit(%__MODULE__{cursor: cursor} = bitstring, value)
      when is_integer(value) do
    bitstring =
      if value > 0 do
        on_bit(bitstring, cursor)
      else
        off_bit(bitstring, cursor)
      end

    %{bitstring | cursor: cursor + 1}
  end

  def set_top_upped_array(binary_data, fullfilled_bytes \\ true) do
    length = byte_size(binary_data) * 8
    array = :binary.bin_to_list(binary_data)
    cursor = length

    bitstring = %__MODULE__{
      length: length,
      array: array,
      cursor: cursor
    }

    if fullfilled_bytes || length == 0 do
      bitstring
    else
      {bitstring, found_end_bit} =
        Enum.reduce_while(0..6, {bitstring, false}, fn _bit, {bitstring, found_end_bit} ->
          cursor = bitstring.cursor - 1

          if get_bit(bitstring, cursor) do
            {:halt, {off_bit(bitstring, cursor), true}}
          else
            {:cont, {%{bitstring | cursor: cursor}, found_end_bit}}
          end
        end)

      unless found_end_bit do
        raise "Incorrect TopUppedArray"
      end

      bitstring
    end
  end

  def get_bit(%__MODULE__{array: array, length: length}, bit_number) do
    check_bit_number(length, bit_number)

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    (byte &&& 1 <<< (7 - rem(bit_number, 8))) > 0
  end

  def off_bit(%__MODULE__{array: array, length: length} = bitstring, bit_number) do
    check_bit_number(length, bit_number)

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    array = List.replace_at(array, idx, byte &&& ~~~(1 <<< (7 - rem(bit_number, 8))))

    %{bitstring | array: array}
  end

  def on_bit(%__MODULE__{array: array, length: length} = bitstring, bit_number) do
    check_bit_number(length, bit_number)

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    array = List.replace_at(array, idx, byte ||| 1 <<< (7 - rem(bit_number, 8)))

    %{bitstring | array: array}
  end

  defp check_bit_number(length, bit_number) do
    if bit_number > length do
      raise "BitString overflow"
    end
  end

  defp pad(str_value, bit_length) do
    pad_size = bit_length - String.length(str_value)

    if pad_size == 0 do
      str_value
    else
      padding =
        "0"
        |> List.duplicate(pad_size)
        |> Enum.join("")

      padding <> str_value
    end
  end
end
