defmodule Ton.Boc do
  @moduledoc """
  Deserialization of cells from a header
  """

  alias Ton.Boc.Header
  alias Ton.Cell

  def parse(binary_data) do
    header = Header.parse(binary_data)

    {reversed_cells, ""} =
      Enum.reduce(1..header.cells_num, {[], header.cells_data}, fn _idx,
                                                                   {cell_acc, remaining_data} ->
        {cell, remaining_data} = Cell.parse(remaining_data, header.size_bytes)

        {[cell | cell_acc], remaining_data}
      end)

    cells = Enum.reverse(reversed_cells)

    cells
    |> Enum.with_index()
    |> Enum.each(fn {cell, index} ->
      Enum.each(cell.refs, fn ref ->
        if ref < index do
          raise "Topological order is broken"
        end
      end)
    end)

    Enum.map(header.root_list, fn root_idx ->
      cells
      |> Enum.at(root_idx)
      |> populate_refs(cells)
    end)
  end

  defp populate_refs(cell, cells) do
    ref_cells =
      Enum.map(cell.refs, fn ref ->
        cells
        |> Enum.at(ref)
        |> populate_refs(cells)
      end)

    %{cell | refs: ref_cells}
  end
end
