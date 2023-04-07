defmodule Ton.Core.Cell.ExoticMekleUpdate do
  alias Ton.Core.BitReader
  alias Ton.Core.Cell

  defstruct [:proof_depth1, :proof_depth2, :proof_hash1, :proof_hash2]

  def parse(bitstring, refs) do
    bitreader = BitReader.new(bitstring)

    # type + hash + hash + depth + depth
    size = 8 + 2 * (256 + 16)

    if bitstring.length != size do
      raise "Merkle Update cell must have exactly (8 + (2 * (256 + 16))) bits, got #{bitstring.length}"
    end

    refs_count = Enum.count(refs)

    if refs_count != 2 do
      raise "Merkle Update cell must have exactly 2 refs, got #{refs_count}"
    end

    type = BitReader.load_uint(bitreader, 8)

    if type != 4 do
      raise "Merkle Update cell type must be exactly 4, got #{type}"
    end

    {bitreader, proof_hash1} = BitReader.load_buffer(bitreader, 32)
    {bitreader, proof_hash2} = BitReader.load_buffer(bitreader, 32)
    {bitreader, proof_depth1} = BitReader.load_uint(bitreader, 16)
    {_bitreader, proof_depth2} = BitReader.load_uint(bitreader, 16)

    ref0 = Enum.at(refs, 0)
    ref1 = Enum.at(refs, 1)

    if proof_depth1 != Cell.depth(ref0, 0) do
      raise "Merkle Update cell ref depth must be exactly #{proof_depth1} got #{Cell.depth(ref0, 0)}"
    end

    if proof_hash1 != Cell.hash(ref0, 0) do
      raise "Merkle Update cell ref hash must be exactly #{proof_hash1}, got #{Cell.hash(ref0, 0)}"
    end

    if proof_depth2 != Cell.depth(ref1, 0) do
      raise "Merkle Update cell ref depth must be exactly #{proof_depth2} got #{Cell.depth(ref1, 0)}"
    end

    if proof_hash2 != Cell.hash(ref1, 0) do
      raise "Merkle Update cell ref hash must be exactly #{proof_hash2}, got #{Cell.hash(ref1, 0)}"
    end

    %__MODULE__{
      proof_depth1: proof_depth1,
      proof_depth2: proof_depth2,
      proof_hash1: proof_hash1,
      proof_hash2: proof_hash2
    }
  end
end
