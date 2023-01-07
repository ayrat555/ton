defmodule Ton.ExternalMessage do
  @moduledoc """
  An external message required to make transfers
  """

  defstruct [:wallet, :common_message_info]

  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.CommonMessageInfo
  alias Ton.Wallet

  @type t :: %__MODULE__{
          wallet: Wallet.t(),
          common_message_info: CommonMessageInfo.t()
        }

  @spec new(Wallet.t(), CommonMessageInfo.t()) :: t()
  def new(wallet, common_message_info) do
    %__MODULE__{wallet: wallet, common_message_info: common_message_info}
  end

  @spec serialize(t(), Cell.t() | nil) :: Cell.t()
  def serialize(external_message, cell \\ nil) do
    cell = cell || Cell.new()

    to_address = %Ton.Address{
      hash: Wallet.hash(external_message.wallet),
      workchain: external_message.wallet.workchain,
      test_only: false,
      bounceable: false,
      workchain: 0
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
