defmodule Ton.Comment do
  @moduledoc """
  Logic for comment serialization
  """

  alias Ton.Bitstring
  alias Ton.Cell

  @spec serialize(String.t(), Cell.t() | nil) :: Cell.t()
  def serialize(comment, cell \\ nil) do
    cell = cell || Cell.new()

    if byte_size(comment) > 0 do
      data = Bitstring.write_uint(cell.data, 0, 32)

      write_comment([%{cell | data: data}], comment)
    else
      cell
    end
  end

  defp write_comment([cell | tail], comment) do
    available_bytes =
      cell.data
      |> Bitstring.available()
      |> Kernel./(8.0)
      |> Float.floor()
      |> trunc()

    if byte_size(comment) <= available_bytes do
      data = Bitstring.write_binary(cell.data, comment)

      set_refs([%{cell | data: data} | tail])
    else
      <<truncated_data::binary-size(available_bytes), remaining_data::binary>> = comment

      data = Bitstring.write_binary(cell.data, truncated_data)

      cell = %{cell | data: data}

      new_cell = Cell.new()

      write_comment([new_cell | [cell | tail]], remaining_data)
    end
  end

  defp set_refs([cell]), do: cell

  defp set_refs([cell1 | [cell2 | tail]]) do
    merged_cell = %{cell2 | refs: cell2.refs ++ [cell1]}

    set_refs([merged_cell | tail])
  end
end
