defmodule Ton.Boc do
  use Bitwise

  @reach_boc_magic_prefix <<181, 238, 156, 114>>
  @lean_boc_magic_prefix <<104, 255, 101, 243>>
  @lean_boc_magic_prefix_crc <<172, 195, 167, 40>>

  def parse_header(binary_data) when byte_size(binary_data) < 5 do
    # TODO: handle gracefully
    raise "not enough bytes for magic prefix"
  end

  def parse_header(binary_data) do
    <<prefix::binary-size(4), serialized_boc::binary>> = binary_data

    has_idx = false
    hash_crc32 = false
    has_cache_bits = false
    flags = 0
    size_bytes = 0

    {has_idx, has_crc32, has_cache_bits, flags, size_bytes} =
      cond do
        prefix == @reach_boc_magic_prefix ->
          <<flags_byte::8, tail::binary>> = serialized_boc

          has_idx = !!(flags_byte &&& 128)
          hash_crc32 = !!(flags_byte &&& 64)
          has_cache_bits = !!(flags_byte &&& 32)
          flags = (flags_byte &&& 16) * 2 + (flags_byte &&& 8)
          size_bytes = rem(flags_byte, 8)

          {has_idx, has_crc32, has_cache_bits, flags, size_bytes}

        prefix == @lean_boc_magic_prefix ->
          <<size_bytes::8, tail::binary>> = serialized_boc

          has_idx = true
          hash_crc32 = false
          has_cache_bits = false
          flags = 0

          {has_idx, has_crc32, has_cache_bits, flags, size_bytes}

        prefix == @lean_boc_magic_prefix_crc ->
          <<size_bytes::8, tail::binary>> = serialized_boc

          has_idx = true
          hash_crc32 = true
          has_cache_bits = false
          flags = 0

          {has_idx, has_crc32, has_cache_bits, flags, size_bytes}

        true ->
          # TODO: handle gracefully
          raise "unknown magic header"
      end

    <<_heade_bytes::8, serialized_boc::binary>> = serialized_boc

    if byte_size(serialized_boc) < 1 + 5 * size_bytes do
      # TODO: handle gracefully
      raise "not enough bytes for encoding cells counters"
    end
  end
end
