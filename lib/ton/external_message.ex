defmodule Ton.ExternalMessage do
  defstruct [:wallet, :common_message_info]

  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.CommonMessageInfo
  alias Ton.Wallet

  def new(wallet, common_message_info) do
    %__MODULE__{wallet: wallet, common_message_info: common_message_info}
  end

  def serialize(external_message, cell \\ nil) do
    cell = cell || Cell.new()

    to_address = %Ton.Address{
      hash: Wallet.hash(external_message.wallet),
      workchain: external_message.wallet.workchain
    }

    data =
      cell.data
      |> Bitstring.write_uint(2, 2)
      |> Bitstring.write_address(nil)
      |> Bitstring.write_address(to_address)
      |> Bitstring.write_coins(0)

    CommonMessageInfo.serialize(external_message.common_message_info, %{cell | data: data})
  end
end
