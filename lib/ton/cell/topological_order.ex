defmodule Ton.Cell.TopologicalOrder do
  alias Ton.Cell

  def sort(root_cell) do
    {all_cells, cell_hashes} = flatten_cells([root_cell])

    sorted_hashes = sort(cell_hashes, MapSet.to_list(all_cells))

    indexes =
      cell_hashes
      |> sort(MapSet.to_list(all_cells))
      |> Enum.with_index()
      |> Map.new()

    Enum.map(sorted_hashes, fn hash ->
      cell = Map.get(all_cells, hash)

      ref_indexes =
        Enum.map(cell.refs, fn ref ->
          Map.get(indexes, ref)
        end)

      %{cell | refs: ref_indexes}
    end)
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

  defp sort(hashes, all_cells, temp_mark \\ MapSet.new(), sorted \\ [])

  defp sort([], _all_cells, _temp_mark, sorted), do: sorted

  defp sort([cell_hash | _tail] = cell_hashes, all_cells, temp_mark, sorted) do
    {new_cell_hashes, new_temp_mark, new_sorted} =
      do_sort(cell_hash, cell_hashes, all_cells, temp_mark, sorted)

    sort(new_cell_hashes, all_cells, new_temp_mark, new_sorted)
  end

  defp do_sort(cell_hash, cell_hashes, all_cells, temp_mark, sorted_acc) do
    if Enum.member?(cell_hashes, cell_hash) do
      {cell_hashes, temp_mark, sorted_acc}
    else
      if Enum.member?(temp_mark, cell_hash) do
        raise "Not a DAG"
      end

      cell = Map.get(all_cells, cell_hash)
      temp_mark = MapSet.put(temp_mark, cell_hash)

      {new_cell_hashes, new_temp_mark, new_sorted_acc} =
        Enum.reduce(cell.refs, {cell_hashes, temp_mark, sorted_acc}, fn ref_cell_hash,
                                                                        {nested_cell_hashes,
                                                                         nested_temp_mark_acc,
                                                                         nested_sorted_acc} ->
          do_sort(
            ref_cell_hash,
            nested_cell_hashes,
            all_cells,
            nested_temp_mark_acc,
            nested_sorted_acc
          )
        end)

      new_sorted_acc = [cell_hash | new_sorted_acc]
      temp_mark = MapSet.delete(new_temp_mark, cell_hash)

      cell_hashes =
        Enum.reject(new_cell_hashes, fn current_cell_hash -> current_cell_hash == cell_hash end)

      {cell_hashes, temp_mark, new_sorted_acc}
    end
  end
end
