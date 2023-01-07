defmodule Ton.Crc16.Impl do
  @moduledoc false

  use Rustler,
    otp_app: :ton,
    crate: :crc16

  def calc(_data), do: :erlang.nif_error(:nif_not_loaded)
end
