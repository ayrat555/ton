defmodule Ton.Crc16 do
  @moduledoc """
  CRC16 hash function
  """

  alias Ton.Crc16.Impl

  @spec calc(binary()) :: binary()
  def calc(data) do
    reg = Impl.calc(data)

    remainder = rem(reg, 256)
    floor_div = Float.floor(reg / 256.0) |> trunc()

    <<floor_div, remainder>>
  end
end
