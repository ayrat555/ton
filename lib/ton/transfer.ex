defmodule Ton.Transfer do
  @moduledoc """
  Defines an actual transfer
  """

  alias Ton.Address
  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.InternalMessage
  alias Ton.Utils

  defstruct [:seqno, :send_mode, :value, :bounce, :timeout, :to, :wallet_id, :body]

  @type t :: %__MODULE__{
          seqno: non_neg_integer(),
          value: non_neg_integer(),
          bounce: boolean(),
          to: Address.t(),
          wallet_id: integer(),
          send_mode: integer(),
          timeout: non_neg_integer(),
          body: binary() | nil
        }

  @spec new(Keyword.t()) :: t()
  def new(params) do
    seqno = Keyword.fetch!(params, :seqno)
    value = Keyword.fetch!(params, :value)
    bounce = Keyword.fetch!(params, :bounce)
    to = Keyword.fetch!(params, :to)
    wallet_id = Keyword.fetch!(params, :wallet_id)
    send_mode = Keyword.get(params, :send_mode, 3)
    body = Keyword.get(params, :body)
    timeout = timeout(params)

    %__MODULE__{
      seqno: seqno,
      send_mode: send_mode,
      value: value,
      bounce: bounce,
      timeout: timeout,
      wallet_id: wallet_id,
      to: to,
      body: body
    }
  end

  @spec serialize(t(), Cell.t() | nil) :: Cell.t()
  def serialize(transfer, cell \\ nil) do
    cell = cell || Cell.new()

    internal_message_cell =
      [to: transfer.to, value: transfer.value, bounce: transfer.bounce, body: transfer.body]
      |> InternalMessage.new()
      |> InternalMessage.serialize()

    data = Bitstring.write_uint(cell.data, transfer.wallet_id, 32)

    data =
      if transfer.seqno == 0 do
        Enum.reduce(0..31, data, fn _i, acc ->
          Bitstring.write_bit(acc, 1)
        end)
      else
        Bitstring.write_uint(data, transfer.timeout, 32)
      end

    data =
      data
      |> Bitstring.write_uint(transfer.seqno, 32)
      |> Bitstring.write_uint8(0)
      |> Bitstring.write_uint8(transfer.send_mode)

    %{cell | data: data, refs: [internal_message_cell]}
  end

  @spec serialize_and_sign(t(), binary()) :: Cell.t()
  def serialize_and_sign(transfer, private_key) do
    transfer_cell = serialize(transfer)

    signature = transfer_cell |> Cell.hash() |> Utils.sign(private_key)

    cell = Cell.new()
    data = Bitstring.write_binary(cell.data, signature)

    serialize(transfer, %{cell | data: data})
  end

  defp timeout(params) do
    case Keyword.get(params, :epoch_timeout) do
      nil ->
        timeout_diff = Keyword.get(params, :timeout, 60)

        DateTime.utc_now()
        |> DateTime.add(timeout_diff)
        |> DateTime.to_unix()

      epoch_timeout ->
        epoch_timeout
    end
  end
end
