defmodule Ton.Core.Cell.LevelMask do
  import Bitwise

  alias Ton.RustUtils

  defstruct [:mask, :hash_index, :hash_count]

  def new(mask) do
    hash_index = count_set_bits(mask)
    hash_count = hash_index + 1

    %__MODULE__{mask: mask, hash_index: hash_index, hash_count: hash_count}
  end

  def level(level_mask) do
    32 - RustUtils.clz32(level_mask.mask)
  end

  def apply(level_mask, level) do
    new(level_mask.mask &&& (1 <<< level) - 1)
  end

  def is_significant(level_mask, level) do
    level == 0 || rem(level_mask.mask >>> (level - 1), 2) != 0
  end

  def count_set_bits(n) do
    n = n - (n >>> 1 &&& 0x55555555)
    n = (n &&& 0x33333333) + (n >>> 2 &&& 0x33333333)

    ((n + (n >>> 4) &&& 0xF0F0F0F) * 0x1010101) >>> 24
  end
end
