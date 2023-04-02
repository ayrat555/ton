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
        a = Enum.random(281_474_976_710_655..-281_474_976_710_655)
        b = Enum.random(281_474_976_710_655..-281_474_976_710_655)

        bitstring =
          BitBuilder.new()
          |> BitBuilder.write_int(a, 49)
          |> BitBuilder.write_int(b, 49)
          |> BitBuilder.build()

        reader = BitReader.new(bitstring)

        assert a == BitReader.preload_int(reader, 49)
        assert {updated_reader, read_value} = BitReader.load_int(reader, 49)
        assert a == read_value

        assert b == BitReader.preload_int(updated_reader, 49)
        assert {updated_reader, read_value} = BitReader.load_int(updated_reader, 49)
        assert b == read_value
        assert 98 == updated_reader.offset
      end)
    end
  end

  describe "load_var_uint/2" do
    test "loads var uint" do
      Enum.each(0..1_000, fn _ ->
        a = :rand.uniform(281_474_976_710_655)
        b = :rand.uniform(281_474_976_710_655)
        size_bits = Enum.random(4..8)

        bitstring =
          BitBuilder.new()
          |> BitBuilder.write_var_uint(a, size_bits)
          |> BitBuilder.write_var_uint(b, size_bits)
          |> BitBuilder.build()

        reader = BitReader.new(bitstring)

        assert a == BitReader.preload_var_uint(reader, size_bits)
        assert {updated_reader, read_value} = BitReader.load_var_uint(reader, size_bits)
        assert a == read_value

        assert b == BitReader.preload_var_uint(updated_reader, size_bits)
        assert {_updated_reader, read_value} = BitReader.load_var_uint(updated_reader, size_bits)
        assert b == read_value
      end)
    end
  end

  describe "load_var_int/2" do
    test "loads var int" do
      Enum.each(0..1_000, fn _ ->
        a = Enum.random(281_474_976_710_655..-281_474_976_710_655)
        b = Enum.random(281_474_976_710_655..-281_474_976_710_655)
        size_bits = Enum.random(4..8)

        bitstring =
          BitBuilder.new()
          |> BitBuilder.write_var_int(a, size_bits)
          |> BitBuilder.write_var_int(b, size_bits)
          |> BitBuilder.build()

        reader = BitReader.new(bitstring)

        assert a == BitReader.preload_var_int(reader, size_bits)
        assert {updated_reader, read_value} = BitReader.load_var_int(reader, size_bits)
        assert a == read_value

        assert b == BitReader.preload_var_int(updated_reader, size_bits)
        assert {_updated_reader, read_value} = BitReader.load_var_int(updated_reader, size_bits)
        assert b == read_value
      end)
    end
  end

  describe "load_coins/1" do
    test "loads coins" do
      Enum.each(0..1_000, fn _ ->
        a = :rand.uniform(281_474_976_710_655)
        b = :rand.uniform(281_474_976_710_655)

        bitstring =
          BitBuilder.new()
          |> BitBuilder.write_coins(a)
          |> BitBuilder.write_coins(b)
          |> BitBuilder.build()

        reader = BitReader.new(bitstring)

        assert a == BitReader.preload_coins(reader)
        assert {updated_reader, read_value} = BitReader.load_coins(reader)
        assert a == read_value

        assert b == BitReader.preload_coins(updated_reader)
        assert {_updated_reader, read_value} = BitReader.load_coins(updated_reader)
        assert b == read_value
      end)
    end
  end
end
