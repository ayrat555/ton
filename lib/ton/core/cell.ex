defmodule Ton.Core.Cell do
  alias Ton.Core.Bitstring

  defstruct [:refs, :bits, :type, :mask]

  def new(params \\ []) do
    bits = Keyword.get(params, :bits, NewBitstring.empty())
    refs = Keyword.get(params, :refs, [])

    if Keyword.get(params, :exotic) do
      # TODO handle exotic

      raise "handle exotic"
    else
      if Enum.count(refs) > 4 do
        raise "Invalid number of references"
      end

      if bits.length > 1023 do
        raise "Bits overflow: #{bits.length} > 1023"
      end
    end
  end
end
