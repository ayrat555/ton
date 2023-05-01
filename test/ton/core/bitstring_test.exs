defmodule Ton.Core.BitstringTest do
  use ExUnit.Case

  alias Ton.Core.BitBuilder
  alias Ton.Core.Bitstring
  alias Ton.Core.Bitstring.CanonicalString

  describe "at/2" do
    test "reads bits" do
      bitstring = Bitstring.new([170], 0, 8)

      assert true == Bitstring.at(bitstring, 0)
      assert false == Bitstring.at(bitstring, 1)
      assert true == Bitstring.at(bitstring, 2)
      assert false == Bitstring.at(bitstring, 3)
      assert true == Bitstring.at(bitstring, 4)
      assert false == Bitstring.at(bitstring, 5)
      assert true == Bitstring.at(bitstring, 6)
      assert false == Bitstring.at(bitstring, 7)
      assert "AA" == CanonicalString.to_string(bitstring)
    end
  end

  describe "equal?/2" do
    test "compares bitstrings" do
      a = Bitstring.new([170], 0, 8)
      b = Bitstring.new([170], 0, 8)
      c = Bitstring.new([0, 170], 8, 8)
      d = Bitstring.new([0, 169], 8, 8)
      e = Bitstring.new([169], 0, 8)

      assert Bitstring.equal?(a, b)
      assert Bitstring.equal?(b, a)
      assert Bitstring.equal?(a, c)
      assert Bitstring.equal?(c, a)
      refute Bitstring.equal?(a, d)
      refute Bitstring.equal?(a, e)

      assert "AA" == CanonicalString.to_string(a)
      assert "AA" == CanonicalString.to_string(b)
      assert "AA" == CanonicalString.to_string(c)
    end
  end

  describe "subbufer/3" do
    test "returns subbufer" do
      bitstring = Bitstring.new([1, 2, 3, 4, 5, 6, 7, 8], 0, 64)
      subbuffer = Bitstring.subbuffer(bitstring, 0, 16)

      assert [1, 2] == subbuffer
    end
  end

  test "processed monkey strings" do
    tests = [
      ["001110101100111010", "3ACEA_"],
      ["01001", "4C_"],
      ["000000110101101010", "035AA_"],
      ["1000011111100010111110111", "87E2FBC_"],
      ["0111010001110010110", "7472D_"],
      ["", ""],
      ["0101", "5"],
      ["010110111010100011110101011110", "5BA8F57A_"],
      ["00110110001101", "3636_"],
      ["1110100", "E9_"],
      ["010111000110110", "5C6D_"],
      ["01", "6_"],
      ["1000010010100", "84A4_"],
      ["010000010", "414_"],
      ["110011111", "CFC_"],
      ["11000101001101101", "C536C_"],
      ["011100111", "73C_"],
      ["11110011", "F3"],
      ["011001111011111000", "67BE2_"],
      ["10101100000111011111", "AC1DF"],
      ["0100001000101110", "422E"],
      ["000110010011011101", "19376_"],
      ["10111001", "B9"],
      ["011011000101000001001001110000", "6C5049C2_"],
      ["0100011101", "476_"],
      ["01001101000001", "4D06_"],
      ["00010110101", "16B_"],
      ["01011011110", "5BD_"],
      ["1010101010111001011101", "AAB976_"],
      ["00011", "1C_"],
      ["11011111111001111100", "DFE7C"],
      ["1110100100110111001101011111000", "E93735F1_"],
      ["10011110010111100110100000", "9E5E682_"],
      ["00100111110001100111001110", "27C673A_"],
      ["01010111011100000000001110000", "57700384_"],
      ["010000001011111111111000", "40BFF8"],
      ["0011110001111000110101100001", "3C78D61"],
      ["101001011011000010", "A5B0A_"],
      ["1111", "F"],
      ["10101110", "AE"],
      ["1001", "9"],
      ["001010010", "294_"],
      ["110011", "CE_"],
      ["10000000010110", "805A_"],
      ["11000001101000100", "C1A24_"],
      ["1", "C_"],
      ["0100101010000010011101111", "4A8277C_"],
      ["10", "A_"],
      ["1010110110110110110100110010110", "ADB6D32D_"],
      ["010100000000001000111101011001", "50023D66_"]
    ]

    Enum.each(tests, fn [bits, result] ->
      bits = String.graphemes(bits)

      bitbuilder =
        Enum.reduce(bits, BitBuilder.new(), fn bit, acc ->
          BitBuilder.write_bit(acc, bit == "1")
        end)

      bitstring = BitBuilder.build(bitbuilder)

      bits
      |> Enum.with_index()
      |> Enum.each(fn {bit, index} ->
        value = bit == "1"

        assert Bitstring.at(bitstring, index) == value
      end)

      assert result == CanonicalString.to_string(bitstring)
    end)
  end
end
