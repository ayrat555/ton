defmodule Ton.Cell do
  defstruct [:refs, :data]

  def max_depth(refs, depth \\ 0)

  def max_depth(%__MODULE__{refs: []}, depth), do: depth

  def max_depth(%__MODULE__{refs: [cell | cell_tail]}, depth) do
    current_cell_depth = max_depth(cell)

    depth =
      if current_cell_depth > depth do
        current_cell_depth + 1
      else
        depth
      end

    max_depth(%__MODULE__{refs: cell_tail}, depth)
  end
end
