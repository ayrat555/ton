defmodule Ton.BitReaderTest do
  use ExUnit.Case

  alias Ton.BitBuilder
  alias Ton.BitReader

  describe "load_uint/2" do
    test "loads uints" do
      Enum.each(0..1_000, fn _ ->
        a = :rand.uniform(281_474_976_710_655)
        b = :rand.uniform(281_474_976_710_655)

        bitstring =
          BitBuilder.new()
          |> BitBuilder.write_uint(a, 48)
          |> BitBuilder.write_uint(b, 48)
          |> BitBuilder.build()

        reader = BitReader.new(bitstring)

        assert a == BitReader.preload_uint(reader, 48)
        assert {updated_reader, read_value} = BitReader.load_uint(reader, 48)
        assert a == read_value

        assert b == BitReader.preload_uint(updated_reader, 48)
        assert {updated_reader, read_value} = BitReader.load_uint(updated_reader, 48)
        assert b == read_value
        assert 96 == updated_reader.offset
      end)
    end
  end

  describe "load_int/2" do
    test "loads ints" do
      Enum.each(0..1_000, fn _ ->
        a = :rand.uniform(281_474_976_710_655)
        b = :rand.uniform(281_474_976_710_655)

        bitstring =
          BitBuilder.new()
          |> BitBuilder.write_uint(a, 48)
          |> BitBuilder.write_uint(b, 48)
          |> BitBuilder.build()

        reader = BitReader.new(bitstring)

        assert a == BitReader.preload_uint(reader, 48)
        assert {updated_reader, read_value} = BitReader.load_uint(reader, 48)
        assert a == read_value

        assert b == BitReader.preload_uint(updated_reader, 48)
        assert {updated_reader, read_value} = BitReader.load_uint(updated_reader, 48)
        assert b == read_value
        assert 96 == updated_reader.offset
      end)
    end
  end
end
