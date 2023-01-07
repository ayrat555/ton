defmodule Ton.Bitstring do
  @moduledoc """
  Defines an array of bits. Data structure used in cells
  """

  import Bitwise

  alias Ton.Address

  defstruct [
    :length,
    :array,
    :cursor
  ]

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          array: [non_neg_integer()],
          cursor: non_neg_integer()
        }

  @spec new(non_neg_integer()) :: t()
  def new(length \\ 1023) do
    size = Float.ceil(length / 8.0) |> trunc()
    array = List.duplicate(0, size)

    %__MODULE__{
      length: length,
      array: array,
      cursor: 0
    }
  end

  @spec write_address(t(), Address.t() | nil) :: t()
  def write_address(bitstring, nil) do
    write_uint(bitstring, 0, 2)
  end

  def write_address(bitstring, address) do
    bitstring
    |> write_uint(2, 2)
    |> write_uint(0, 1)
    |> write_uint(address.workchain, 8)
    |> write_binary(address.hash)
  end

  @spec write_coins(t(), non_neg_integer()) :: t()
  def write_coins(bitstring, 0) do
    write_uint(bitstring, 0, 4)
  end

  def write_coins(bitstring, value) when is_integer(value) do
    str_value = Integer.to_string(value, 16)

    l =
      str_value
      |> String.length()
      |> Kernel./(2.0)
      |> Float.ceil()
      |> trunc()

    bitstring
    |> write_uint(l, 4)
    |> write_uint(value, l * 8)
  end

  @spec write_binary(t(), binary()) :: t()
  def write_binary(bitstring, data) do
    data
    |> :binary.bin_to_list()
    |> Enum.reduce(bitstring, fn byte, acc ->
      write_uint8(acc, byte)
    end)
  end

  @spec write_bistring(t(), t()) :: t()
  def write_bistring(bitstring, %__MODULE__{cursor: cursor} = second_bitstring) do
    Enum.reduce(0..(cursor - 1), bitstring, fn idx, acc ->
      bit = get_bit(second_bitstring, idx)

      write_bit(acc, bit)
    end)
  end

  @spec write_uint8(t(), non_neg_integer()) :: t()
  def write_uint8(bitstring, value) do
    write_uint(bitstring, value, 8)
  end

  @spec write_uint(t(), non_neg_integer(), non_neg_integer()) :: t()
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

  @spec write_bit(t(), boolean() | non_neg_integer()) :: t()
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

  @spec set_top_upped_array(binary(), boolean()) :: t() | no_return()
  def set_top_upped_array(
        binary_data,
        fullfilled_bytes \\ true
      ) do
    length = byte_size(binary_data) * 8

    cursor = length

    array =
      binary_data
      |> :binary.bin_to_list()

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
          bitstring = %{bitstring | cursor: bitstring.cursor - 1}

          if get_bit(bitstring, bitstring.cursor) do
            {:halt, {off_bit(bitstring, bitstring.cursor), true}}
          else
            {:cont, {bitstring, found_end_bit}}
          end
        end)

      unless found_end_bit do
        raise "Incorrect TopUppedArray"
      end

      bitstring
    end
  end

  @spec get_top_upped_array(t()) :: binary()
  def get_top_upped_array(bitstring) do
    top_up = (Float.ceil(bitstring.cursor / 8.0) |> trunc) * 8 - bitstring.cursor

    bitstring =
      if top_up > 0 do
        bitstring = write_bit(bitstring, true)

        Enum.reduce((top_up - 2)..0, bitstring, fn _bit, bitstring_acc ->
          bitstring = write_bit(bitstring_acc, false)

          bitstring
        end)
      else
        bitstring
      end

    last_idx = Float.ceil(bitstring.cursor / 8.0) |> trunc()
    {result, _} = Enum.split(bitstring.array, last_idx)

    :binary.list_to_bin(result)
  end

  @spec get_top_upped_length(t()) :: non_neg_integer()
  def get_top_upped_length(%__MODULE__{cursor: cursor}) do
    Float.ceil(cursor / 8.0) |> trunc()
  end

  @spec get_bit(t(), non_neg_integer()) :: boolean()
  def get_bit(%__MODULE__{array: array, length: length}, bit_number) do
    check_bit_number(length, bit_number)

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    (byte &&& 1 <<< (7 - rem(bit_number, 8))) > 0
  end

  @spec off_bit(t(), non_neg_integer()) :: t()
  def off_bit(%__MODULE__{array: array, length: length} = bitstring, bit_number) do
    check_bit_number(length, bit_number)

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    array = List.replace_at(array, idx, byte &&& ~~~(1 <<< (7 - rem(bit_number, 8))))

    %{bitstring | array: array}
  end

  @spec on_bit(t(), non_neg_integer()) :: t()
  def on_bit(%__MODULE__{array: array, length: length} = bitstring, bit_number) do
    check_bit_number(length, bit_number)

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    array = List.replace_at(array, idx, byte ||| 1 <<< (7 - rem(bit_number, 8)))

    %{bitstring | array: array}
  end

  @spec available(t()) :: non_neg_integer()
  def available(%__MODULE__{cursor: cursor, length: length}) do
    length - cursor
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
