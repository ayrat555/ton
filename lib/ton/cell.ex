defmodule Ton.Cell do
  @moduledoc """
  Cell data structure used in serialization and deserialization
  """
  import Bitwise

  defstruct [:refs, :data, :kind]

  alias Ton.Bitstring
  alias Ton.Boc.Header
  alias Ton.Cell.TopologicalOrder
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

    {kind, data_byte_size, cell_data} =
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

        {kind, data_byte_size - 1, cell_data}
      else
        {:ordinary, data_byte_size, cell_data}
      end

    <<data::binary-size(data_byte_size), cell_data::binary>> = cell_data

    bits = Bitstring.set_top_upped_array(data, fullfilled_bytes)

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

  def serialize(root_cell, opts \\ []) do
    has_idx = Keyword.get(opts, :has_idx, true)
    hash_crc32 = Keyword.get(opts, :hash_crc32, true)
    has_cache_bits = Keyword.get(opts, :has_cache_bits, false)
    flags = Keyword.get(opts, :flags, 0)

    all_cells = TopologicalOrder.sort(root_cell)
    cells_num = Enum.count(all_cells)
    s = Integer.to_string(cells_num, 2) |> String.length()
    s_bytes = max(Float.ceil(s / 8.0) |> trunc(), 1)

    sizes =
      Enum.map(all_cells, fn cell ->
        calc_serialized_cell_size(cell.cell, s_bytes)
      end)

    {full_size, size_indexes_reversed} =
      Enum.reduce(sizes, {0, []}, fn size, {full_size_acc, size_indexes_acc} ->
        current_size = full_size_acc + size

        {current_size, [current_size | size_indexes_acc]}
      end)

    size_indexes = Enum.reverse(size_indexes_reversed)
    offset_bits = Integer.to_string(full_size, 2) |> String.length()
    offset_bytes = max(Float.ceil(offset_bits / 8.0) |> trunc(), 1)

    serialization = Header.reach_boc_magic_prefix()

    serialization =
      serialization <>
        <<if(has_idx, do: 1, else: 0) <<< 7 ||| if(hash_crc32, do: 1, else: 0) <<< 6 |||
            if(has_cache_bits, do: 1, else: 0) <<< 5 ||| flags <<< 3 ||| s_bytes>>

    serialization =
      (serialization <> <<offset_bytes>>)
      |> write_number(cells_num, s_bytes)
      |> write_number(1, s_bytes)
      |> write_number(0, s_bytes)
      |> write_number(full_size, offset_bytes)
      |> write_number(0, s_bytes)

    serialization =
      if has_idx do
        Enum.reduce(size_indexes, serialization, fn size_index, acc ->
          write_number(acc, size_index, offset_bytes)
        end)
      else
        serialization
      end

    serialization =
      Enum.reduce(all_cells, serialization, fn cell, acc ->
        serialize_for_boc(acc, cell.cell, cell.refs, s_bytes)
      end)

    if hash_crc32 do
      serialization <> EvilCrc32c.calc!(serialization)
    else
      serialization
    end
  end

  defp calc_serialized_cell_size(cell, s) do
    2 +
      if(cell.kind == :ordinary, do: 0, else: 1) +
      Bitstring.get_top_upped_length(cell.data) +
      Enum.count(cell.refs) * s
  end

  defp serialize_for_boc(binary, cell, refs, s_size) do
    refs_descriptor = refs_descriptor(cell)
    bits_descriptor = bits_descriptor(cell)

    binary = binary <> refs_descriptor <> bits_descriptor

    binary =
      case cell.kind do
        :pruned -> binary <> <<1>>
        :library_reference -> binary <> <<2>>
        :merkle_proof -> binary <> <<3>>
        :merkle_update -> binary <> <<4>>
        :ordinary -> binary
      end

    binary = binary <> Bitstring.get_top_upped_array(cell.data)

    Enum.reduce(refs, binary, fn ref_index, acc ->
      write_number(acc, ref_index, s_size)
    end)
  end

  defp write_number(binary, number, bytes) do
    number_bin =
      Enum.reduce((bytes - 1)..0, <<>>, fn i, acc ->
        acc <> <<number >>> (i * 8) &&& 0xFF>>
      end)

    binary <> number_bin
  end

  def hash(cell) do
    cell
    |> binary_repr()
    |> Utils.sha256()
  end

  def binary_repr(cell) do
    data = data_with_descriptors(cell)

    data =
      Enum.reduce(cell.refs, data, fn ref_cell, acc ->
        max_depth_bin = max_depth_as_bin(ref_cell)
        acc <> max_depth_bin
      end)

    result =
      Enum.reduce(cell.refs, data, fn ref_cell, acc ->
        hash = hash(ref_cell)

        acc <> hash
      end)

    result
  end

  def data_with_descriptors(cell) do
    d1 = refs_descriptor(cell)
    d2 = bits_descriptor(cell)

    tu_bits = Bitstring.get_top_upped_array(cell.data)

    d1 <> d2 <> tu_bits
  end

  def refs_descriptor(cell) do
    # different for exotic cells
    <<Enum.count(cell.refs)>>
  end

  def bits_descriptor(cell) do
    # different for exotic cells

    len = cell.data.cursor

    ceil = Float.ceil(len / 8.0) |> trunc()
    floor = Float.floor(len / 8.0) |> trunc()

    <<ceil + floor>>
  end

  def max_level(_cell) do
    # different for exotic cells
    0
  end

  def max_depth_as_bin(cell) do
    max_depth = max_depth(cell)

    d1 = rem(max_depth, 256)
    d2 = Float.floor(max_depth / 256.0) |> trunc()

    <<d2, d1>>
  end

  def max_depth(refs)

  def max_depth(%__MODULE__{refs: []}), do: 0

  def max_depth(%__MODULE__{refs: cells}) do
    result =
      Enum.reduce(cells, 0, fn ref_cell, acc ->
        current_cell_depth = max_depth(ref_cell)

        if current_cell_depth > acc do
          current_cell_depth
        else
          acc
        end
      end)

    result + 1
  end

  def write_cell(cell, another_cell) do
    new_data = Bitstring.write_bistring(cell.data, another_cell.data)

    %{cell | refs: cell.refs ++ another_cell.refs, data: new_data}
  end
end
