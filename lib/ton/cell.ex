defmodule Ton.Cell do
  import Bitwise

  defstruct [:refs, :data, :kind]

  alias Ton.Bitstring
  alias Ton.Utils

  def new(kind \\ :ordinary, data \\ nil) do
    data = data || Bitstring.new(1023)

    %__MODULE__{
      data: data,
      kind: kind,
      refs: []
    }
  end

  def parse(binary_data, reference_index_size) do
    if byte_size(binary_data) < 2 do
      raise "Not enough bytes to encode cell descriptors"
    end

    <<d1::8, d2::8, cell_data::binary>> = binary_data

    is_exotic = (d1 &&& 8) != 0
    ref_num = rem(d1, 8)
    data_byte_size = Float.ceil(d2 / 2.0) |> trunc()
    fullfilled_bytes = rem(d2, 2) == 0

    if byte_size(cell_data) < data_byte_size + reference_index_size * ref_num do
      raise "Not enough bytes to encode cell data"
    end

    {kind, cell_data} =
      if is_exotic do
        <<kind_byte::8, cell_data::binary>> = cell_data

        kind =
          case kind_byte do
            1 -> :pruned
            2 -> :library_reference
            3 -> :merkle_proof
            4 -> :merkle_update
            _ -> raise "Invalid cell type: #{kind_byte}"
          end

        {kind, cell_data}
      else
        {:ordinary, cell_data}
      end

    <<data::binary-size(data_byte_size), cell_data::binary>> = cell_data

    bits = Bitstring.set_top_upped_array(Bitstring.new(), data, fullfilled_bytes)

    {reversed_refs, residue} =
      if ref_num != 0 do
        Enum.reduce(1..ref_num, {[], cell_data}, fn _idx, {refs, current_cell_data} ->
          {ref, current_cell_data} =
            Utils.read_n_bytes_uint(current_cell_data, reference_index_size)

          {[ref | refs], current_cell_data}
        end)
      else
        {[], cell_data}
      end

    refs = Enum.reverse(reversed_refs)

    {%__MODULE__{refs: refs, data: bits, kind: kind}, residue}
  end

  def hash(cell) do
    cell
    |> binary_repr()
    |> ExKeccak.hash_256()
  end

  def binary_repr(cell) do
    data = data_with_descriptors(cell)

    data =
      Enum.reduce(cell.refs, data, fn ref_cell, acc ->
        max_depth_bin = max_depth_as_bin(ref_cell)
        acc <> max_depth_bin
      end)

    Enum.reduce(cell.refs, data, fn ref_cell, acc ->
      hash = hash(ref_cell)

      acc <> hash
    end)
  end

  def data_with_descriptors(cell) do
    d1 = refs_descriptor(cell)
    d2 = bits_descriptor(cell)
    tu_bits = Bitstring.get_top_upped_array(cell.data)

    d1 <> d2 <> tu_bits
  end

  def refs_descriptor(cell) do
    # TODO: different for exotic cells
    <<Enum.count(cell.refs)>>
  end

  def bits_descriptor(cell) do
    # TODO: different for exotic cells

    len = cell.data.cursor

    ceil = Float.ceil(len / 8.0) |> trunc()
    floor = Float.ceil(len / 8.0) |> trunc()

    <<ceil + floor>>
  end

  def max_level(_cell) do
    # TODO: different for exotic cells
    0
  end

  def max_depth_as_bin(cell) do
    max_depth = max_depth(cell)

    d1 = rem(max_depth, 256)
    d2 = Float.floor(max_depth / 256.0) |> trunc()

    <<d1, d2>>
  end

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
