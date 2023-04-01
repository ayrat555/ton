defmodule Ton.RustUtils do
  use Rustler, otp_app: :ton, crate: :rust_utils

  def clz32(_number), do: :erlang.nif_error(:nif_not_loaded)
end
