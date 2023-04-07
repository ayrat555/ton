defmodule Ton.Core.Cell.ExoticLibrary do
  alias Ton.Core.BitReader

  def parse(bitstring, _refs) do
    bitreader = BitReader.new(bitstring)
    # type + hash
    size = 8 + 256

    if bitstring.length != size do
      raise "Library cell must have exactly (8 + 256) bits, got #{bitstring.length}"
    end

    type = BitReader.load_uint(bitreader, 8)

    if type != 2 do
      raise "Library cell must have type 2, got #{type}"
    end
  end
end
