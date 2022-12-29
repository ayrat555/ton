defmodule Ton.Transfer do
  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.InternalMessage
  alias Ton.Utils

  defstruct [:seqno, :send_mode, :value, :bounce, :timeout, :to, :wallet_id]

  def new(params) do
    seqno = Keyword.fetch!(params, :seqno)
    value = Keyword.fetch!(params, :value)
    bounce = Keyword.fetch!(params, :bounce)

    to = Keyword.fetch!(params, :to)
    wallet_id = Keyword.fetch!(params, :wallet_id)
    send_mode = Keyword.get(params, :send_mode, 3)

    timeout_diff = Keyword.get(params, :timeout, 60)

    timeout =
      DateTime.utc_now()
      |> DateTime.add(timeout_diff)
      |> DateTime.to_unix()

    %__MODULE__{
      seqno: seqno,
      send_mode: send_mode,
      value: value,
      bounce: bounce,
      timeout: timeout,
      wallet_id: wallet_id,
      to: to
    }
  end

  def serialize(transfer, cell \\ nil) do
    cell = cell || Cell.new()

    internal_message_cell =
      [to: transfer.to, value: transfer.value, bounce: transfer.bounce]
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

  def serialize_and_sign(transfer, private_key) do
    transfer_cell = serialize(transfer)
    {:ok, signature} = transfer_cell |> Cell.hash() |> Utils.sign(private_key)

    cell = Cell.new()
    data = Bitstring.write_binary(cell.data, signature)

    serialize(transfer, %{cell | data: data})
  end
end
