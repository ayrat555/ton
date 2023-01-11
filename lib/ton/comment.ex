defmodule Ton.Comment do
  @moduledoc """
  Logic for comment serialization
  """

  alias Ton.Bitstring
  alias Ton.Cell

  @spec serialize(String.t() | nil, Cell.t() | nil) :: Cell.t()
  def serialize(comment, cell \\ nil) do
    cell = cell || Cell.new()

    write_comment([cell], comment)

    if byte_size(comment) > 0 do
      write_comment([cell], comment)
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

  defp set_refs(cells) do
    [main_cell | refs] = Enum.reverse(cells)

    %{main_cell | refs: main_cell.refs ++ refs}
  end
end
