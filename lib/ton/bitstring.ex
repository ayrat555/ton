defmodule Ton.Bitstring do
  import Bitwise

  defstruct [
    :length,
    :array,
    :cursor
  ]

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
    if bit_number > length do
      raise "BitString overflow"
    end

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    (byte &&& 1 <<< (7 - rem(bit_number, 8))) > 0
  end

  def off_bit(%__MODULE__{array: array, length: length} = bitstring, bit_number) do
    if bit_number > length do
      raise "BitString overflow"
    end

    idx = div(bit_number, 8) ||| 0
    byte = Enum.at(array, idx)

    array = List.replace_at(array, idx, byte &&& ~~~(1 <<< (7 - rem(bit_number, 8))))

    %{bitstring | array: array}
  end
end
