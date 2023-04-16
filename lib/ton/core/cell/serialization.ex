defmodule Ton.Core.Cell.Serialization do
  import Bitwise

  alias Ton.Core.BitBuilder
  alias Ton.Cell.TopologicalOrder
  alias Ton.Core.BitReader
  alias Ton.Core.Bitstring
  alias Ton.Core.Cell
  alias Ton.Core.Cell.Descriptor
  alias Ton.Core.Utils

  def read_cell(reader, size_bytes) do
    {reader, d1} = BitReader.load_uint(reader, 8)
    refs_count = rem(d1, 8)
    exotic = (d1 &&& 8) != 0

    {reader, d2} = BitReader.load_uint(reader, 8)
    data_byte_size = Float.ceil(d2 / 2.0) |> trunc()
    padding_added = rem(d2, 2) == 0

    # bits
    {bitreader, bits} =
      cond do
        data_byte_size <= 0 -> Bitstring.empty()
        padding_added -> BitReader.load_padded_bits(reader, data_byte_size * 8)
        true -> BitReader.load_bits(reader, data_byte_size * 8)
      end

    # refs

    {bitreader, refs_reversed} =
      if refs_count > 0 do
        Enum.reduce(0..(refs_count - 1), {bitreader, []}, fn {bitreader, acc} ->
          {bitreader, ref} = BitReader.load_uint(bitreader, size_bytes * 8)

          {bitreader, [ref | acc]}
        end)
      else
        {bitreader, []}
      end

    refs = Enum.reverse(refs_reversed)

    {bitreader, Cell.new(bits: bits, refs: refs, exotic: exotic)}
  end

  def calc_cell_size(cell, size_bytes) do
    2 + (Float.ceil(cell.bits.length / 8.0) |> trunc()) + Enum.count(cell.refs) * size_bytes
  end

  def parse_boc(src) do
    reader = src |> Bitstring.new(0, byte_size(src)) |> BitReader.new()
    {reader, magic} = BitReader.load_uint(reader, 32)

    case magic do
      0x68FF65F3 ->
        {reader, size} = BitReader.load_uint(reader, 8)
        {reader, off_bytes} = BitReader.load_uint(reader, 8)
        {reader, cells} = BitReader.load_uint(reader, size * 8)
        {reader, roots} = BitReader.load_uint(reader, size * 8)
        {reader, absent} = BitReader.load_uint(reader, size * 8)
        {reader, total_cell_size} = BitReader.load_uint(reader, off_bytes * 8)
        {reader, index} = BitReader.load_buffer(reader, cells * off_bytes)
        {_reader, cell_data} = BitReader.load_buffer(reader, total_cell_size)

        %{
          size: size,
          off_bytes: off_bytes,
          cells: cells,
          roots: roots,
          absent: absent,
          total_cell_size: total_cell_size,
          index: index,
          cell_data: cell_data,
          root: [0]
        }

      0xACC3A728 ->
        {reader, size} = BitReader.load_uint(reader, 8)
        {reader, off_bytes} = BitReader.load_uint(reader, 8)
        {reader, cells} = BitReader.load_uint(reader, size * 8)
        {reader, roots} = BitReader.load_uint(reader, size * 8)
        {reader, absent} = BitReader.load_uint(reader, size * 8)
        {reader, total_cell_size} = BitReader.load_uint(reader, off_bytes * 8)
        {reader, index} = BitReader.load_buffer(reader, cells * off_bytes)
        {_reader, cell_data} = BitReader.load_buffer(reader, total_cell_size)

        binary_data_size = byte_size(src)

        <<binary_data_without_hash::binary-size(binary_data_size - 4),
          expected_hashsum::binary-size(4)>> = src

        if EvilCrc32c.crc32c!(binary_data_without_hash) != expected_hashsum do
          raise "Invalid CRC32C"
        end

        %{
          size: size,
          off_bytes: off_bytes,
          cells: cells,
          roots: roots,
          absent: absent,
          total_cell_size: total_cell_size,
          index: index,
          cell_data: cell_data,
          root: [0]
        }

      0xB5EE9C72 ->
        {reader, has_idx} = BitReader.load_uint(reader, 1)
        {reader, has_crc32c} = BitReader.load_uint(reader, 1)
        {reader, _has_cache_bits} = BitReader.load_uint(reader, 1)
        # Must be 0
        {reader, _flags} = BitReader.load_uint(reader, 2)
        {reader, size} = BitReader.load_uint(reader, 3)
        {reader, off_bytes} = BitReader.load_uint(reader, 8)
        {reader, cells} = BitReader.load_uint(reader, size * 8)
        {reader, roots} = BitReader.load_uint(reader, size * 8)
        {reader, absent} = BitReader.load_uint(reader, size * 8)
        {reader, total_cell_size} = BitReader.load_uint(reader, size * 8)

        {reader, root_reversed} =
          Enum.reduce(0..(roots - 1), {reader, []}, fn _, {reader, acc} ->
            {reader, cell} = BitReader.load_uint(reader, size * 8)

            {reader, [cell | acc]}
          end)

        root = Enum.reverse(root_reversed)

        {reader, index} =
          if has_idx != 0 do
            BitReader.load_uint(reader, cells * off_bytes)
          else
            {reader, nil}
          end

        {_reader, cell_data} = BitReader.load_buffer(reader, total_cell_size)

        if has_crc32c do
          binary_data_size = byte_size(src)

          <<binary_data_without_hash::binary-size(binary_data_size - 4),
            expected_hashsum::binary-size(4)>> = src

          if EvilCrc32c.crc32c!(binary_data_without_hash) != expected_hashsum do
            raise "Invalid CRC32C"
          end
        end

        %{
          size: size,
          off_bytes: off_bytes,
          cells: cells,
          roots: roots,
          absent: absent,
          total_cell_size: total_cell_size,
          index: index,
          cell_data: cell_data,
          root: root
        }

      _ ->
        raise "Invalid magic"
    end
  end

  def deserialize_boc(src) do
    boc = parse_boc(src)

    reader =
      boc.cell_data
      |> Bitstring.new(0, byte_size(boc.cell_data) * 8)
      |> BitReader.new()

    # cells

    {_reader, result_cells} =
      if boc.cells > 0 do
        Enum.reduce(0..(boc.cells - 1), {reader, []}, fn _i, {reader, acc} ->
          {reader, cell} = read_cell(reader, boc.size)

          {reader, [%{cell: cell, result: nil} | acc]}
        end)
      else
        {reader, []}
      end

    result_cells =
      Enum.reduce((Enum.count(result_cells) - 1)..0, result_cells, fn i, acc ->
        result_cell = Enum.at(acc, i)

        if result_cell.result do
          raise "Impossible"
        end

        refs =
          result_cell.refs
          |> Enum.reduce([], fn ref_idx, _acc ->
            ref = Enum.at(result_cells, ref_idx)

            if is_nil(ref.result) do
              raise "Invalid BOC file"
            end

            [ref | ref.result]
          end)
          |> Enum.reverse()

        updated_result_cell =
          Map.put(
            result_cell,
            :result,
            Cell.new(bits: result_cell.bits, refs: refs, exotic: result_cell.exotic)
          )

        List.replace_at(result_cells, i, updated_result_cell)
      end)

    Enum.map(boc.root, fn root_idx ->
      Enum.at(result_cells, root_idx)
    end)
  end

  def write_cell_to_builder(cell, refs, size_bytes, to) do
    d1 = Descriptor.get_refs_descriptor(cell.refs, Cell.level(cell), cell.type)
    d2 = Descriptor.get_bits_descriptor(cell.bits)

    padded_buffer = Utils.padded_buffer(cell.bits)

    bitbuilder =
      to
      |> BitBuilder.write_uint(d1, 8)
      |> BitBuilder.write_uint(d2, 8)
      |> BitBuilder.write_buffer(padded_buffer)

    Enum.reduce(refs, bitbuilder, fn ref, acc ->
      BitBuilder.write_uint(acc, ref, size_bytes * 8)
    end)
  end

  def serialize_boc(root, has_idx \\ false, has_crc32c \\ false) do
    all_cells = TopologicalOrder.sort(root)
    cells_num = Enum.count(all_cells)
    has_cache_bits = false
    flags = 0

    size_bytes =
      Enum.max([
        cells_num
        |> Utils.bits_for_number(:uint)
        |> Kernel./(8.0)
        |> Float.ceil()
        |> trunc(),
        1
      ])

    {total_cell_size, index_reversed} =
      Enum.reduce(all_cells, {0, []}, fn c, {total_cell_size_acc, index_acc} ->
        size = calc_cell_size(c.cell, size_bytes)

        {total_cell_size_acc + size, [size | index_acc]}
      end)

    index = Enum.reverse(index_reversed)

    offset_bytes =
      Enum.max([
        total_cell_size
        |> Utils.bits_for_number(:uint)
        |> Kernel./(8.0)
        |> Float.ceil()
        |> trunc(),
        1
      ])

    # magic
    # flags and s_bytes
    # offset_bytes
    # cells_num, roots, complete
    # root_idx
    total_size =
      (4 +
         1 +
         1 +
         3 * size_bytes +
         offset_bytes +
         1 * size_bytes +
         if(has_idx, do: cells_num * offset_bytes, else: 0) +
         total_cell_size +
         if(has_crc32c, do: 4, else: 0)) * 8

    builder =
      total_size
      |> BitBuilder.new()
      # Magic
      |> BitBuilder.write_uint(0xB5EE9C72, 32)
      # Has index
      |> BitBuilder.write_bit(has_idx)
      # Has crc32c
      |> BitBuilder.write_bit(has_crc32c)
      # Has cache bits
      |> BitBuilder.write_bit(has_cache_bits)
      # Flags
      |> BitBuilder.write_uint(flags, 2)
      # Size bytes
      |> BitBuilder.write_uint(size_bytes, 3)
      # Offset bytes
      |> BitBuilder.write_uint(offset_bytes, 8)
      # Cells num
      |> BitBuilder.write_uint(cells_num, size_bytes * 8)
      # Roots num
      |> BitBuilder.write_uint(1, size_bytes * 8)
      # Absent num
      |> BitBuilder.write_uint(0, size_bytes * 8)
      # Total cell size
      |> BitBuilder.write_uint(total_cell_size, offset_bytes * 8)
      # Root id == 0
      |> BitBuilder.write_uint(0, size_bytes * 8)

    builder =
      if has_idx do
        Enum.reduce(index, builder, fn ind, acc ->
          BitBuilder.write_uint(acc, ind, offset_bytes * 8)
        end)
      else
        builder
      end

    builder =
      Enum.reduce(all_cells, builder, fn cell, acc ->
        write_cell_to_builder(cell.cell, cell.refs, size_bytes, acc)
      end)

    builder =
      if has_crc32c do
        crc32 = EvilCrc32c.crc32c!(builder.buffer)
        BitBuilder.write_buffer(builder, crc32)
      else
        builder
      end

    res = BitBuilder.build(builder)

    if res.length != div(total_size, 8) do
      raise "Internal error"
    end

    res
  end
end
