defmodule Ton.InternalMessage do
  alias Ton.Bitstring
  alias Ton.Cell

  defstruct [:to, :value, :bounce]

  def new(params) do
    to = Keyword.fetch!(params, :to)
    value = Keyword.fetch!(params, :value)
    bounce = Keyword.fetch!(params, :bounce)

    %__MODULE__{to: to, value: value, bounce: bounce}
  end

  def serialize(internal_message) do
    cell = Cell.new()

    data =
      cell.data
      # message id
      |> Bitstring.write_bit(0)
      # ihrDisabled
      |> Bitstring.write_bit(true)
      # bounce
      |> Bitstring.write_bit(internal_message.bounce)
      # bounced
      |> Bitstring.write_bit(false)
      # to address
      |> Bitstring.write_address(internal_message.to)
      # from address
      |> Bitstring.write_address(nil)
      # coins
      |> Bitstring.write_coins(internal_message.value)
      # currency collection not supported
      |> Bitstring.write_bit(false)
      # ihrFees
      |> Bitstring.write_coins(0)
      # ihrFees
      |> Bitstring.write_coins(0)
      # createdLt
      |> Bitstring.write_uint(0, 64)
      # createdAt
      |> Bitstring.write_uint(0, 32)

    %{cell | data: data}
  end
end
