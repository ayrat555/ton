defmodule Ton.Boc do
  alias Ton.Boc.Header
  alias Ton.Cell

  defstruct [
    :header,
    :cells
  ]

  def parse(binary_data) do
    header = Header.parse(binary_data)

    {reversed_cells, ""} =
      Enum.reduce(1..header.cells_num, {[], header.cells_data}, fn _idx,
                                                                   {cell_acc, remaining_data} ->
        {cell, remaining_data} = Cell.parse(remaining_data, header.size_bytes)

        {[cell | cell_acc], remaining_data}
      end)

    cells = Enum.reverse(reversed_cells)

    %__MODULE__{
      header: header,
      cells: cells
    }
  end
end
