defmodule Ton.Crc16 do
  @moduledoc false

  use Rustler,
    otp_app: :ton,
    crate: :crc16

  def calc(data) do
    reg = do_calc(data)

    remainder = rem(reg, 256)
    floor_div = Float.floor(reg / 256.0) |> trunc()

    <<floor_div, remainder>>
  end

  def do_calc(_data), do: :erlang.nif_error(:nif_not_loaded)
end
