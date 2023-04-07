defmodule Ton.Core.Cell.ExoticPruned do
  alias Ton.Core.BitReader
  alias Ton.Core.Cell.LevelMask

  defstruct [:mask, :pruned]

  def parse(bitstring, refs) do
    bitreader = BitReader.new(bitstring)

    # Check type
    {bitreader, type} = BitReader.load_uint(bitreader, 8)

    if type != 1 do
      raise "Pruned branch cell must have type 1, got #{type}"
    end

    # Check refs
    refs_count = Enum.count(refs)

    if refs_count != 0 do
      raise "Pruned Branch cell can't has refs, got #{refs_count}"
    end

    {bitreader, mask, mask_level} =
      if bitstring.length == 280 do
        # Special case for config proof
        # This test proof is generated in the moment of voting for a slashing
        # it seems that tools generate it incorrectly and therefore doesn't have mask in it
        # so we need to hardcode it equal to 1
        level_mask = LevelMask.new(1)

        {bitreader, level_mask, LevelMask.level(level_mask)}
      else
        {bitreader, mask} = BitReader.load_uint(bitreader, 8)
        level_mask = LevelMask.new(mask)

        level = LevelMask.level(level_mask)

        if level < 1 || level > 3 do
          raise "Pruned Branch cell level must be >= 1 and <= 3, got #{level}/#{mask.mask}"
        end

        size = LevelMask.apply(level_mask, level - 1).hash_count * (256 + 16) + 16

        if bitstring.length != size do
          raise "Pruned branch cell must have exactly ${size} bits, got #{bitstring.length}"
        end

        {bitreader, level_mask, level}
      end

    {bitreader, hashes} =
      Enum.reduce(0..(mask_level - 1), {bitreader, []}, fn _, {bitreader, hashes} ->
        {bitreader, hash} = BitReader.load_buffer(bitreader, 32)

        {bitreader, [hash | hashes]}
      end)

    hashes = Enum.reverse(hashes)

    {_bitreader, depths} =
      Enum.reduce(0..(mask_level - 1), {bitreader, []}, fn _, {bitreader, depths} ->
        {bitreader, depth} = BitReader.load_buffer(bitreader, 16)

        {bitreader, [depth | depths]}
      end)

    depths = Enum.reverse(depths)

    pruned =
      Enum.reduce(0..(mask_level - 1), [], fn i, acc ->
        depth = Enum.at(depths, i)
        hash = Enum.at(hashes, i)

        pruned = %{depth: depth, hash: hash}

        [pruned | acc]
      end)

    pruned = Enum.reverse(pruned)

    %__MODULE__{mask: mask.mask, pruned: pruned}
  end
end
