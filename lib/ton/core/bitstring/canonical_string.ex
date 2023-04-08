defmodule Ton.Core.Bitstring.CanonicalString do
  alias Ton.Core.BitBuilder
  alias Ton.Core.Bitstring
  alias Ton.Core.Utils

  def to_string(%Bitstring{length: 0}), do: ""

  def to_string(bitstring) do
    padded_buffer = Utils.padded_buffer(bitstring)

    if rem(bitstring.length, 4) == 0 do
      result =
        padded_buffer
        |> Enum.slice(0, Utils.complete_bytes(bitstring.length))
        |> :binary.list_to_bin()
        |> Base.encode16(case: :upper)

      if rem(bitstring.length, 8) == 0 do
        result
      else
        length = String.length(result)

        String.slice(result, 0, length - 1)
      end
    else
      result =
        padded_buffer
        |> :binary.list_to_bin()
        |> Base.encode16(case: :upper)

      if rem(bitstring.length, 8) <= 4 do
        length = String.length(result)

        String.slice(result, 0, length - 1) <> "_"
      else
        result <> "_"
      end
    end
  end
end
