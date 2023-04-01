defmodule Ton.NewBitstring do
  import Bitwise

  defstruct [:data, :offset, :length]

  @type t :: %__MODULE__{
          data: [non_neg_integer()],
          offset: non_neg_integer(),
          length: non_neg_integer()
        }

  @spec new([non_neg_integer()], non_neg_integer(), non_neg_integer()) :: t()
  def new(data, offset, length) do
    if length < 0 do
      raise "Length #{length} is out of bound"
    end

    %__MODULE__{
      data: data,
      offset: offset,
      length: length
    }
  end

  @spec empty() :: t()
  def empty do
    %__MODULE__{
      data: [],
      offset: 0,
      length: 0
    }
  end

  @spec at(t(), non_neg_integer()) :: boolean()
  def at(bitstring, index) do
    if index >= bitstring.length do
      raise "Index #{index} >= #{bitstring.length} is out of bounds"
    end

    if index < 0 do
      raise "Index #{index} < 0 is out of bounds"
    end

    byte_index = (bitstring.offset + index) >>> 3
    bit_index = 7 - rem(bitstring.offset + index, 8)

    byte = Enum.at(bitstring.data, byte_index)

    (byte &&& 1 <<< bit_index) != 0
  end

  @spec substring(t(), non_neg_integer(), non_neg_integer()) :: t()
  def substring(%__MODULE__{length: offset}, offset, 0), do: new("", 0, 0)

  def substring(bitstring, offset, length) do
    if offset >= bitstring.length do
      raise "Offset #{offset} >= #{bitstring.length} is out of bounds"
    end

    if offset < 0 do
      raise "Offset(#{offset}) < 0 is out of bounds"
    end

    if offset + length > bitstring.length do
      raise "Offset #{offset} + Length #{length} > #{bitstring.length} is out of bounds"
    end

    new(bitstring.data, bitstring.offset + offset, length)
  end

  @spec subbuffer(t(), non_neg_integer(), non_neg_integer()) :: binary()
  def subbuffer(bitstring, offset, length) do
    if offset >= bitstring.length do
      raise "Offset #{offset} >= #{bitstring.length} is out of bounds"
    end

    if offset < 0 do
      raise "Offset(#{offset}) < 0 is out of bounds"
    end

    if offset + length > bitstring.length do
      raise "Offset #{offset} + Length #{length} > #{bitstring.length} is out of bounds"
    end

    start_idx = (bitstring.offset + offset) >>> 3
    end_idx = start_idx + (length >>> 3)

    Enum.slice(bitstring.data, start_idx, end_idx)
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(bitstring1, bitstring2) do
    if bitstring1.length != bitstring2.length do
      false
    else
      Enum.reduce_while(0..(bitstring1.length - 1), true, fn idx, _acc ->
        if at(bitstring1, idx) != at(bitstring2, idx) do
          {:halt, false}
        else
          {:cont, true}
        end
      end)
    end
  end
end
