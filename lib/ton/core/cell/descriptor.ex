defmodule Ton.Core.Cell.Descriptor do
  alias Ton.Core.Cell
  alias Ton.Core.Utils

  def get_refs_descriptor(refs, level, type) do
    Enum.count(refs) + if(type != :ordinary, do: 1, else: 0) * 8 + level * 32
  end

  def get_bits_descriptor(bits) do
    len = bits.length

    ceil =
      len
      |> Kernel./(8.0)
      |> Float.ceil()
      |> trunc()

    floor =
      len
      |> Kernel./(8.0)
      |> Float.floor()
      |> trunc()

    ceil + floor
  end

  def get_repr(bits, refs, level, type) do
    refs_descriptor = get_refs_descriptor(refs, level, type)
    bits_descriptor = get_bits_descriptor(bits)

    acc = <<refs_descriptor, bits_descriptor>>

    padded_bits =
      bits
      |> Utils.padded_buffer()
      |> :binary.list_to_bin()

    acc = acc <> padded_bits

    acc =
      Enum.reduce(refs, acc, fn ref, inner_acc ->
        child_depth =
          if type == :merkle_proof || type == :merkle_update do
            Cell.depth(ref, level + 1)
          else
            Cell.depth(ref, level)
          end

        value1 = Float.floor(child_depth / 256.0) |> trunc()
        value2 = rem(child_depth, 256)

        inner_acc <> <<value1, value2>>
      end)

    Enum.reduce(refs, acc, fn ref, inner_acc ->
      child_hash =
        if type == :merkle_proof || type == :merkle_update do
          Cell.hash(ref, level + 1)
        else
          Cell.hash(ref, level)
        end

      inner_acc <> child_hash
    end)
  end
end
