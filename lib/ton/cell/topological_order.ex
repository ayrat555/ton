defmodule Ton.Cell.TopologicalOrder do
  alias Ton.Cell

  def sort(root_cell) do
    flatten_cells([root_cell])
  end

  defp flatten_cells(cells, acc \\ {%{}, MapSet.new()})

  defp flatten_cells([], acc), do: acc

  defp flatten_cells(cells, {all_cells, uniq_hashes}) do
    {new_all_cells, new_uniq_hashes, new_cells_reversed} =
      Enum.reduce(cells, {all_cells, uniq_hashes, []}, fn cell,
                                                          {all_cells_acc, uniq_hashes_acc,
                                                           current_cells_acc} ->
        hash = Cell.hash(cell)

        case Map.get(all_cells_acc, hash) do
          nil ->
            ref_hashes =
              Enum.map(cell.refs, fn ref ->
                Cell.hash(ref)
              end)

            cell_wrapper = %{cell: cell, refs: ref_hashes}
            new_all_cells_acc = Map.put(all_cells_acc, hash, cell_wrapper)
            new_uniq_hashes_acc = MapSet.put(uniq_hashes_acc, hash)
            new_current_cells_acc = Enum.concat(current_cells_acc, cell.refs)

            {new_all_cells_acc, new_uniq_hashes_acc, new_current_cells_acc}

          _ ->
            {all_cells_acc, uniq_hashes_acc, current_cells_acc}
        end
      end)

    new_cells = Enum.reverse(new_cells_reversed)

    flatten_cells(new_cells, {new_all_cells, new_uniq_hashes})
  end
end
