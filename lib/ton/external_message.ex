defmodule Ton.ExternalMessage do
  defstruct [:to, :common_message_info]

  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.CommonMessageInfo

  def new(to, common_message_info) do
    %__MODULE__{to: to, common_message_info: common_message_info}
  end

  def serialize(external_message, cell \\ nil) do
    cell = cell || Cell.new()

    data =
      cell.data
      |> Bitstring.write_uint(2, 2)
      |> Bitstring.write_address(nil)
      |> Bitstring.write_address(external_message.to)
      |> Bitstring.write_coins(0)

    CommonMessageInfo.serialize(external_message.common_message_info, %{cell | data: data})
  end
end
