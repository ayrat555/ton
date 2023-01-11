defmodule Ton.CommonMessageInfo do
  @moduledoc """
  Common message info used in an external message
  """

  alias Ton.Bitstring
  alias Ton.Cell
  alias Ton.Wallet

  defstruct [
    :wallet,
    :body
  ]

  @type t :: %__MODULE__{
          wallet: Wallet.t(),
          body: Cell.t()
        }

  @spec new(Wallet.t() | nil, Cell.t() | nil) :: t()
  def new(wallet \\ nil, body \\ nil) do
    %__MODULE__{wallet: wallet, body: body}
  end

  @spec serialize(t(), Cell.t() | nil) :: Cell.t()
  def serialize(info, cell \\ nil) do
    cell = cell || Cell.new()

    cell_with_state_init =
      if info.wallet do
        cell = %{cell | data: Bitstring.write_bit(cell.data, 1)}
        state_init_cell = Wallet.state_init_cell(info.wallet)

        if Bitstring.available(cell.data) - 1 >= state_init_cell.data.cursor do
          data = Bitstring.write_bit(cell.data, 0)

          Cell.write_cell(%{cell | data: data}, state_init_cell)
        else
          data = Bitstring.write_bit(cell.data, 1)

          %{cell | data: data, refs: cell.refs ++ [state_init_cell]}
        end
      else
        data = Bitstring.write_bit(cell.data, 0)

        %{cell | data: data}
      end

    if info.body do
      if Bitstring.available(cell_with_state_init.data) >= info.body.data.cursor do
        data = Bitstring.write_bit(cell_with_state_init.data, 0)

        Cell.write_cell(%{cell_with_state_init | data: data}, info.body)
      else
        data = Bitstring.write_bit(cell_with_state_init.data, 1)

        %{cell_with_state_init | data: data, refs: cell.refs ++ [info.body]}
      end
    else
      data = Bitstring.write_bit(cell_with_state_init.data, 0)

      %{cell | data: data}
    end
  end
end
