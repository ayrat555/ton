defmodule Ton.Bitwise do
  import Bitwise

  @max_32_bit 2_147_483_647
  @min_32_bit -2_147_483_648

  def bixor(num1, num2) do
    bxor_result = bxor(num1, num2)

    if bxor_result > @max_32_bit do
      -1
    else
      bxor_result
    end
  end
end
