defmodule Ton.Core.Cell do
  alias Ton.Core.Bitstring
  alias Ton.Core.Cell.Exotic
  alias Ton.Core.Cell.WonderCalculator

  defstruct [:refs, :bits, :type, :mask, :depths, :hashes]

  def new(params \\ []) do
    bits = Keyword.get(params, :bits, Bitstring.empty())
    refs = Keyword.get(params, :refs, [])

    {mask, depths, hashes, type} =
      if Keyword.get(params, :exotic) do
        resolved = Exotic.resolve(bits, refs)
        wonders = WonderCalculator.calculate(resolved.type, bits, refs)

        {wonders.mask, wonders.depths, wonders.hashes, resolved.type}
      else
        if Enum.count(refs) > 4 do
          raise "Invalid number of references"
        end

        if bits.length > 1023 do
          raise "Bits overflow: #{bits.length} > 1023"
        end

        wonders = WonderCalculator.calculate(:ordinary, bits, refs)

        {wonders.mask, wonders.depths, wonders.hashes, :ordinary}
      end

    %__MODULE__{type: type, refs: refs, bits: bits, mask: mask, depths: depths, hashes: hashes}
  end

  def exotic?(cell) do
    cell.type != :ordinary
  end

  def hash(cell, level \\ 3) do
    level = Enum.min([Enum.count(cell.hashes) - 1, level])

    Enum.at(cell.hashes, level)
  end

  def level(cell) do
    cell.mask.level
  end

  def depth(cell, level \\ 3) do
    level = Enum.min([Enum.count(cell.depths) - 1, level])

    Enum.at(cell.depths, level)
  end
end
