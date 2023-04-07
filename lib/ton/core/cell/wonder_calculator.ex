defmodule Ton.Core.Cell.WonderCalculator do
  import Bitwise

  alias Ton.NewCell.LevelMask

  def calculate(type, bits, refs) do
    case type do
      :ordinary ->
        mask =
          Enum.reduce(refs, 0, fn ref, acc ->
            acc ||| ref.mask.value
          end)

        LevelMask.new(mask)

      :merkle_proof ->
        nil
    end
  end
end
