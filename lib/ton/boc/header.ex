defmodule Ton.Boc.Header do
  @moduledoc """
  Logic used for contract deserialization from the BOC format
  """

  import Bitwise

  alias Ton.Utils

  defstruct [
    :has_idx,
    :hash_crc32,
    :has_cache_bits,
    :flags,
    :size_bytes,
    :off_bytes,
    :cells_num,
    :roots_num,
    :absent_num,
    :tot_cells_size,
    :root_list,
    :index,
    :cells_data
  ]

  @type t :: %__MODULE__{
          has_idx: boolean(),
          hash_crc32: boolean(),
          has_cache_bits: boolean(),
          flags: non_neg_integer(),
          size_bytes: non_neg_integer(),
          off_bytes: non_neg_integer(),
          cells_num: non_neg_integer(),
          roots_num: non_neg_integer(),
          absent_num: non_neg_integer(),
          tot_cells_size: non_neg_integer(),
          root_list: [non_neg_integer()],
          index: [non_neg_integer()],
          cells_data: binary()
        }

  @reach_boc_magic_prefix <<181, 238, 156, 114>>
  @lean_boc_magic_prefix <<104, 255, 101, 243>>
  @lean_boc_magic_prefix_crc <<172, 195, 167, 40>>

  @spec parse(binary()) :: t() | no_return()
  def parse(binary_data) when byte_size(binary_data) < 5 do
    raise "not enough bytes for magic prefix"
  end

  def parse(binary_data) do
    <<prefix::binary-size(4), serialized_boc::binary>> = binary_data

    {has_idx, hash_crc32, has_cache_bits, flags, size_bytes} =
      cond do
        prefix == @reach_boc_magic_prefix ->
          <<flags_byte::8, _tail::binary>> = serialized_boc

          has_idx = (flags_byte &&& 128) != 0
          hash_crc32 = (flags_byte &&& 64) != 0
          has_cache_bits = (flags_byte &&& 32) != 0
          flags = (flags_byte &&& 16) * 2 + (flags_byte &&& 8)
          size_bytes = rem(flags_byte, 8)

          {has_idx, hash_crc32, has_cache_bits, flags, size_bytes}

        prefix == @lean_boc_magic_prefix ->
          <<size_bytes::8, _tail::binary>> = serialized_boc

          has_idx = true
          hash_crc32 = false
          has_cache_bits = false
          flags = 0

          {has_idx, hash_crc32, has_cache_bits, flags, size_bytes}

        prefix == @lean_boc_magic_prefix_crc ->
          <<size_bytes::8, _tail::binary>> = serialized_boc

          has_idx = true
          hash_crc32 = true
          has_cache_bits = false
          flags = 0

          {has_idx, hash_crc32, has_cache_bits, flags, size_bytes}

        true ->
          raise "unknown magic header"
      end

    <<_heade_bytes::8, serialized_boc::binary>> = serialized_boc

    if byte_size(serialized_boc) < 1 + 5 * size_bytes do
      raise "not enough bytes for encoding cells counters"
    end

    <<offset_bytes::8, serialized_boc::binary>> = serialized_boc

    {cells_num, serialized_boc} = Utils.read_n_bytes_uint(serialized_boc, size_bytes)
    {roots_num, serialized_boc} = Utils.read_n_bytes_uint(serialized_boc, size_bytes)
    {absent_num, serialized_boc} = Utils.read_n_bytes_uint(serialized_boc, size_bytes)
    {tot_cells_size, serialized_boc} = Utils.read_n_bytes_uint(serialized_boc, offset_bytes)

    if byte_size(serialized_boc) < roots_num * size_bytes do
      raise "Not enough bytes for encoding root cells hashes"
    end

    {reversed_root_list, serialized_boc} =
      Enum.reduce(1..roots_num, {[], serialized_boc}, fn _,
                                                         {root_list_acc, current_serialized_boc} ->
        {root, serialized_boc} = Utils.read_n_bytes_uint(current_serialized_boc, size_bytes)
        {[root | root_list_acc], serialized_boc}
      end)

    root_list = Enum.reverse(reversed_root_list)

    {reversed_index, serialized_boc} =
      if has_idx do
        if byte_size(serialized_boc) < offset_bytes * cells_num do
          raise "Not enough bytes for index encoding"
        else
          Enum.reduce(1..cells_num, {[], serialized_boc}, fn _,
                                                             {cells_list_acc,
                                                              current_serialized_boc} ->
            {index, serialized_boc} = Utils.read_n_bytes_uint(current_serialized_boc, size_bytes)
            {[index | cells_list_acc], serialized_boc}
          end)
        end
      else
        {[], serialized_boc}
      end

    index = Enum.reverse(reversed_index)

    if byte_size(serialized_boc) < tot_cells_size do
      raise "Not enough bytes for cells data"
    end

    <<cells_data::binary-size(tot_cells_size), serialized_boc::binary>> = serialized_boc

    serialized_boc =
      if hash_crc32 do
        if byte_size(serialized_boc) < 4 do
          raise "Not enough bytes for crc32c hashsum"
        end

        binary_data_size = byte_size(binary_data)

        <<binary_data_without_hash::binary-size(binary_data_size - 4),
          expected_hashsum::binary-size(4)>> = binary_data

        if EvilCrc32c.crc32c!(binary_data_without_hash) != expected_hashsum do
          raise "crc32c hashsum mismatch"
        end

        <<_offset_bytes::binary-size(4), serialized_boc::binary>> = serialized_boc

        serialized_boc
      else
        serialized_boc
      end

    if byte_size(serialized_boc) != 0 do
      raise "too much bytes in BoC serialization"
    end

    %__MODULE__{
      has_idx: has_idx,
      hash_crc32: hash_crc32,
      has_cache_bits: has_cache_bits,
      flags: flags,
      size_bytes: size_bytes,
      off_bytes: offset_bytes,
      cells_num: cells_num,
      roots_num: roots_num,
      absent_num: absent_num,
      tot_cells_size: tot_cells_size,
      root_list: root_list,
      index: index,
      cells_data: cells_data
    }
  end

  @spec reach_boc_magic_prefix() :: binary()
  def reach_boc_magic_prefix, do: @reach_boc_magic_prefix

  @spec lean_boc_magic_prefix() :: binary()
  def lean_boc_magic_prefix, do: @lean_boc_magic_prefix

  @spec lean_boc_magic_prefix_crc() :: binary()
  def lean_boc_magic_prefix_crc, do: @lean_boc_magic_prefix_crc
end
