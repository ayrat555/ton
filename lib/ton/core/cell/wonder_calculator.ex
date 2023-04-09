defmodule Ton.Core.Cell.WonderCalculator do
  import Bitwise

  alias Ton.Core.Bitstring
  alias Ton.Core.Cell.Descriptor
  alias Ton.Core.Cell.ExoticLibrary
  alias Ton.Core.Cell.ExoticMekleProof
  alias Ton.Core.Cell.ExoticMekleUpdate
  alias Ton.Core.Cell.ExoticPruned
  alias Ton.Core.Cell.LevelMask
  alias Ton.Core.Cell
  alias Ton.Utils

  defstruct [:mask, :hashes, :depths]

  def calculate(type, bits, refs) do
    {level_mask, pruned} =
      case type do
        :ordinary ->
          mask =
            Enum.reduce(refs, 0, fn ref, acc ->
              acc ||| ref.mask.mask
            end)

          {LevelMask.new(mask), nil}

        :pruned_branch ->
          pruned = ExoticPruned.parse(bits, refs)

          {LevelMask.new(pruned.mask), pruned}

        :merkle_proof ->
          ExoticMekleProof.parse(bits, refs)

          ref = Enum.at(refs, 0)

          {LevelMask.new(ref.mask.mask >>> 1), nil}

        :mekle_update ->
          ExoticMekleUpdate.parse(bits, refs)

          ref0 = Enum.at(refs, 0)
          ref1 = Enum.at(refs, 1)

          {LevelMask.new((ref0.mask.mask ||| ref1.mask.mask) >>> 1), nil}

        :library ->
          ExoticLibrary.parse(bits, refs)

          {LevelMask.new(), nil}

        _ ->
          raise "Unsupported exotic type"
      end

    hash_count = if type == :pruned_branch, do: 1, else: level_mask.hash_count
    total_hash_count = level_mask.hash_count
    hash_i_offset = total_hash_count - hash_count

    {depths, hashes, _} =
      Enum.reduce(0..LevelMask.level(level_mask), {%{}, %{}, 0}, fn level_i,
                                                                    {depths, hashes, hash_i} ->
        cond do
          !LevelMask.is_significant(level_mask, level_i) ->
            {depths, hashes, hash_i}

          hash_i < hash_i_offset ->
            {depths, hashes, hash_i + 1}

          true ->
            # bits
            current_bits =
              if hash_i == hash_i_offset do
                if !(level_i == 0 || type == :pruned_branch) do
                  raise "Invalid"
                end

                bits
              else
                if !(level_i != 0 && type != :pruned_branch) do
                  raise "Invalid: #{level_i}, type #{type}"
                end

                hash = Enum.at(hashes, hash_i - hash_i_offset - 1)
                Bitstring.new(hash, 0, 256)
              end

            # depth

            current_depth =
              refs
              |> Enum.reduce(0, fn ref, acc ->
                child_depth =
                  if type == :merkle_proof || type == :merkle_update do
                    Cell.depth(ref, level_i + 1)
                  else
                    Cell.depth(ref, level_i)
                  end

                Enum.max([child_depth, acc])
              end)

            current_depth =
              if Enum.count(refs) > 0 do
                current_depth + 1
              else
                current_depth
              end

            # hash

            repr = Descriptor.get_repr(current_bits, refs, level_i, type)
            hash = Utils.sha256(repr)

            # persist next

            dest_i = hash_i - hash_i_offset
            depths = Map.put(depths, dest_i, current_depth)
            hashes = Map.put(hashes, dest_i, hash)

            {depths, hashes, hash_i + 1}
        end
      end)

    # Calculate hash and depth for all levels

    {resolved_hashes, resolved_depths} =
      if pruned do
        Enum.reduce(0..3, {[], []}, fn i, {resolved_hashes, resolved_depths} ->
          hash_index = LevelMask.apply(level_mask, i).hash_index
          this_hash_index = level_mask.hash_index

          if hash_index != this_hash_index do
            prun = Enum.at(pruned, hash_index)

            {[prun.hash | resolved_hashes], [prun.depth | resolved_depths]}
          else
            hash = Map.get(hashes, 0)
            depth = Map.get(depths, 0)

            {[hash | resolved_hashes], [depth | resolved_depths]}
          end
        end)
      else
        Enum.reduce(0..3, {[], []}, fn i, {resolved_hashes, resolved_depths} ->
          index = LevelMask.apply(level_mask, i).hash_index

          hash = Map.get(hashes, index)
          depth = Map.get(depths, index)

          {[hash | resolved_hashes], [depth | resolved_depths]}
        end)
      end

    %__MODULE__{
      mask: level_mask,
      hashes: Enum.reverse(resolved_hashes),
      depths: Enum.reverse(resolved_depths)
    }
  end
end
