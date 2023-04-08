defmodule Ton.Core.Cell.Exotic do
  import Bitwise

  alias Ton.Core.BitReader
  alias Ton.Core.Cell.ExoticLibrary
  alias Ton.Core.Cell.ExoticMekleProof
  alias Ton.Core.Cell.ExoticMekleUpdate
  alias Ton.Core.Cell.ExoticPruned
  alias Ton.Core.Cell.LevelMask

  defstruct [:type, :depths, :hashes, :mask]

  def resolve(bits, refs) do
    reader = BitReader.new(bits)
    type = BitReader.preload_uint(reader, 8)

    case type do
      1 -> resolve_pruned(bits, refs)
      2 -> resolve_library(bits, refs)
      3 -> resolve_merkle_proof(bits, refs)
      4 -> resolve_merkle_update(bits, refs)
      _ -> raise "Invalid exotic cell type #{type}"
    end
  end

  defp resolve_pruned(bits, refs) do
    pruned = ExoticPruned.parse(bits, refs)

    {depths, hashes} =
      Enum.reduce(pruned.pruned, {[], []}, fn prun, {depths_acc, hashes_acc} ->
        {[prun.depth | depths_acc], [prun.hash | hashes_acc]}
      end)

    %__MODULE__{
      type: :pruned_branch,
      depths: depths,
      hashes: hashes,
      mask: LevelMask.new(pruned.mask)
    }
  end

  defp resolve_library(bits, refs) do
    ExoticLibrary.parse(bits, refs)

    %__MODULE__{
      type: :library,
      depths: [],
      hashes: [],
      mask: LevelMask.new()
    }
  end

  defp resolve_merkle_proof(bits, refs) do
    ExoticMekleProof.parse(bits, refs)

    %__MODULE__{
      type: :merkle_proof,
      depths: [],
      hashes: [],
      mask: LevelMask.new(Enum.at(refs, 0).level >>> 1)
    }
  end

  defp resolve_merkle_update(bits, refs) do
    ExoticMekleUpdate.parse(bits, refs)

    %__MODULE__{
      type: :merkle_update,
      depths: [],
      hashes: [],
      mask: LevelMask.new((Enum.at(refs, 0).level ||| Enum.at(refs, 1).level) >>> 1)
    }
  end
end
