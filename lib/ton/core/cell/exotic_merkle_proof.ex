defmodule Ton.Core.Cell.ExoticMekleProof do
  alias Ton.Core.BitReader
  alias Ton.Core.Cell

  defstruct [:proof_depth, :proof_hash]

  def parse(bitstring, refs) do
    bitreader = BitReader.new(bitstring)

    # type + hash + depth
    size = 8 + 256 + 16

    if bitstring.length != size do
      raise "Merkle Proof cell must have exactly (8 + 256 + 16) bits, got #{bitstring.length}"
    end

    # Check refs
    refs_count = Enum.count(refs)

    if refs_count != 1 do
      raise "Merkle Proof cell must have exactly 1 ref, got #{refs_count}"
    end

    {bitreader, type} = BitReader.load_uint(bitreader, 8)

    if type != 3 do
      raise "Merkle Proof cell must have type 3, got #{type}"
    end

    {bitreader, proof_hash} = BitReader.load_buffer(bitreader, 32)
    {_bitreader, proof_depth} = BitReader.load_uint(bitreader, 16)

    ref_cell = Enum.at(refs, 0)
    ref_hash = Cell.hash(ref_cell, 0)
    ref_depth = Cell.depth(ref_cell, 0)

    if proof_depth != ref_depth do
      raise "Merkle Proof cell ref depth must be exactly #{proof_depth}, got #{ref_depth}"
    end

    if proof_hash != ref_hash do
      "Merkle Proof cell ref hash must be exactly #{proof_hash}, got #{ref_hash}"
    end

    %__MODULE__{
      proof_depth: proof_depth,
      proof_hash: proof_hash
    }
  end
end
