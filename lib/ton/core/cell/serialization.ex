defmodule Ton.Core.Cell.Serialization do
  import Bitwise

  alias Ton.Core.BitReader
  alias Ton.Core.Bitstring
  alias Ton.Core.Cell

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
        padding_added -> Bitreader.load_padded_bits(reader, data_byte_size * 8)
        true -> Bitreader.load_bits(reader, data_byte_size * 8)
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
    reader = src |> Bitstring.new(src, 0, byte_size(src)) |> BitReader.new()
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
        {reader, has_cache_bits} = BitReader.load_uint(reader, 1)
        {reader, flags} = BitReader.load_uint(reader, 2)
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

        {reader, cell_data} = BitReader.load_buffer(reader, total_cell_size)

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
      parsed_boc.cell_data
      |> BitString.new(0, byte_size(parsed_boc.cell_data) * 8)
      |> BitReader.new()

    # cells

    {reader, result_cells} =
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
          |> Enum.reduce([], fn ref_idx, acc ->
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

    Enum.map(boc.root, [], fn root_idx ->
      Enum.at(result_cells, root_idx)
    end)
  end
end
