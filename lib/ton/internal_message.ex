defmodule Ton.InternalMessage do
  @moduledoc false

  alias Ton.Address
  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.CommonMessageInfo
  alias Ton.Comment

  defstruct [:to, :value, :bounce, :body]

  @type t :: %__MODULE__{
          to: Address.t(),
          value: non_neg_integer(),
          bounce: boolean(),
          body: CommonMessageInfo.t()
        }

  @spec new(Keyword.t()) :: t()
  def new(params) do
    to = Keyword.fetch!(params, :to)
    value = Keyword.fetch!(params, :value)
    bounce = Keyword.fetch!(params, :bounce)

    body =
      case Keyword.get(params, :body) do
        body when is_binary(body) ->
          comment = Comment.serialize(body)

          CommonMessageInfo.new(nil, comment)

        _ ->
          CommonMessageInfo.new(nil, nil)
      end

    %__MODULE__{to: to, value: value, bounce: bounce, body: body}
  end

  @spec serialize(t()) :: Cell.t()
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
      # from address
      |> Bitstring.write_address(nil)
      # to address
      |> Bitstring.write_address(internal_message.to)
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
      # state init
      |> Bitstring.write_bit(0)

    # state body
    CommonMessageInfo.serialize(internal_message.body, %{cell | data: data})
  end
end
