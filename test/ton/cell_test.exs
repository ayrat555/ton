defmodule Ton.CellTest do
  use ExUnit.Case

  alias Ton.Boc
  alias Ton.Cell

  describe "parse/2" do
    test "parses cells" do
      data =
        <<1, 20, 255, 0, 244, 164, 19, 244, 188, 242, 200, 11, 1, 2, 1, 32, 2, 3, 2, 1, 72, 4, 5,
          4, 248, 242, 131, 8, 215, 24, 32, 211, 31, 211, 31, 211, 31, 2, 248, 35, 187, 242, 100,
          237, 68, 208, 211, 31, 211, 31, 211, 255, 244, 4, 209, 81, 67, 186, 242, 161, 81, 81,
          186, 242, 162, 5, 249, 1, 84, 16, 100, 249, 16, 242, 163, 248, 0, 36, 164, 200, 203, 31,
          82, 64, 203, 31, 82, 48, 203, 255, 82, 16, 244, 0, 201, 237, 84, 248, 15, 1, 211, 7, 33,
          192, 0, 159, 108, 81, 147, 32, 215, 74, 150, 211, 7, 212, 2, 251, 0, 232, 48, 224, 33,
          192, 1, 227, 0, 33, 192, 2, 227, 0, 1, 192, 3, 145, 48, 227, 13, 3, 164, 200, 203, 31,
          18, 203, 31, 203, 255, 16, 17, 18, 19, 2, 230, 208, 1, 208, 211, 3, 33, 113, 176, 146,
          95, 4, 224, 34, 215, 73, 193, 32, 146, 95, 4, 224, 2, 211, 31, 33, 130, 16, 112, 108,
          117, 103, 189, 34, 130, 16, 100, 115, 116, 114, 189, 176, 146, 95, 5, 224, 3, 250, 64,
          48, 32, 250, 68, 1, 200, 202, 7, 203, 255, 201, 208, 237, 68, 208, 129, 1, 64, 215, 33,
          244, 4, 48, 92, 129, 1, 8, 244, 10, 111, 161, 49, 179, 146, 95, 7, 224, 5, 211, 63, 200,
          37, 130, 16, 112, 108, 117, 103, 186, 146, 56, 48, 227, 13, 3, 130, 16, 100, 115, 116,
          114, 186, 146, 95, 6, 227, 13, 6, 7, 2, 1, 32, 8, 9, 0, 120, 1, 250, 0, 244, 4, 48, 248,
          39, 111, 34, 48, 80, 10, 161, 33, 190, 242, 224, 80, 130, 16, 112, 108, 117, 103, 131,
          30, 177, 112, 128, 24, 80, 4, 203, 5, 38, 207, 22, 88, 250, 2, 25, 244, 0, 203, 105, 23,
          203, 31, 82, 96, 203, 63, 32, 201, 128, 64, 251, 0, 6, 0, 138, 80, 4, 129, 1, 8, 244,
          89, 48, 237, 68, 208, 129, 1, 64, 215, 32, 200, 1, 207, 22, 244, 0, 201, 237, 84, 1,
          114, 176, 142, 35, 130, 16, 100, 115, 116, 114, 131, 30, 177, 112, 128, 24, 80, 5, 203,
          5, 80, 3, 207, 22, 35, 250, 2, 19, 203, 106, 203, 31, 203, 63, 201, 128, 64, 251, 0,
          146, 95, 3, 226, 2, 1, 32, 10, 11, 0, 89, 189, 36, 43, 111, 106, 38, 132, 8, 10, 6, 185,
          15, 160, 33, 132, 112, 212, 8, 8, 71, 164, 147, 125, 41, 145, 12, 230, 144, 62, 159,
          249, 131, 120, 18, 128, 27, 120, 16, 20, 137, 135, 21, 159, 49, 132, 2, 1, 88, 12, 13,
          0, 17, 184, 201, 126, 212, 77, 13, 112, 177, 248, 0, 61, 178, 157, 251, 81, 52, 32, 64,
          80, 53, 200, 125, 1, 12, 0, 178, 50, 129, 242, 255, 242, 116, 0, 96, 64, 66, 61, 2, 155,
          232, 76, 96, 2, 1, 32, 14, 15, 0, 25, 173, 206, 118, 162, 104, 64, 32, 107, 144, 235,
          133, 255, 192, 0, 25, 175, 29, 246, 162, 104, 64, 16, 107, 144, 235, 133, 143, 192, 0,
          110, 210, 7, 250, 0, 212, 212, 34, 249, 0, 5, 200, 202, 7, 21, 203, 255, 201, 208, 119,
          116, 128, 24, 200, 203, 5, 203, 2, 34, 207, 22, 80, 5, 250, 2, 20, 203, 107, 18, 204,
          204, 201, 115, 251, 0, 200, 64, 20, 129, 1, 8, 244, 81, 242, 167, 2, 0, 112, 129, 1, 8,
          215, 24, 250, 0, 211, 63, 200, 84, 32, 71, 129, 1, 8, 244, 81, 242, 167, 130, 16, 110,
          111, 116, 101, 112, 116, 128, 24, 200, 203, 5, 203, 2, 80, 6, 207, 22, 80, 4, 250, 2,
          20, 203, 106, 18, 203, 31, 203, 63, 201, 115, 251, 0, 2, 0, 108, 129, 1, 8, 215, 24,
          250, 0, 211, 63, 48, 82, 36, 129, 1, 8, 244, 89, 242, 167, 130, 16, 100, 115, 116, 114,
          112, 116, 128, 24, 200, 203, 5, 203, 2, 80, 5, 207, 22, 80, 3, 250, 2, 19, 203, 106,
          203, 31, 18, 203, 63, 201, 115, 251, 0, 0, 10, 244, 0, 201, 237, 84>>

      {reversed_cells, ""} =
        Enum.reduce(1..20, {[], data}, fn _idx, {acc, data_acc} ->
          {cell, remaining_data} = Cell.parse(data_acc, 1)

          {[cell | acc], remaining_data}
        end)

      assert [
               %Ton.Cell{
                 refs: [1],
                 data: %Ton.Bitstring{
                   length: 80,
                   array: [255, 0, 244, 164, 19, 244, 188, 242, 200, 11],
                   cursor: 80
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [2, 3],
                 data: %Ton.Bitstring{length: 8, array: [0], cursor: 3},
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [4, 5],
                 data: %Ton.Bitstring{length: 8, array: [64], cursor: 5},
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [16, 17, 18, 19],
                 data: %Ton.Bitstring{
                   length: 992,
                   array: _,
                   cursor: 992
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [6, 7],
                 data: %Ton.Bitstring{
                   length: 920,
                   array: _,
                   cursor: 920
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [8, 9],
                 data: %Ton.Bitstring{length: 8, array: [0], cursor: 3},
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 480,
                   array: _,
                   cursor: 480
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 552,
                   array: _,
                   cursor: 552
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [10, 11],
                 data: %Ton.Bitstring{length: 8, array: [0], cursor: 3},
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 360,
                   array: _,
                   cursor: 358
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [12, 13],
                 data: %Ton.Bitstring{length: 8, array: [80], cursor: 5},
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 72,
                   array: [184, 201, 126, 212, 77, 13, 112, 177, 240],
                   cursor: 69
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 248,
                   array: _,
                   cursor: 243
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [14, 15],
                 data: %Ton.Bitstring{length: 8, array: [0], cursor: 3},
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 104,
                   array: [173, 206, 118, 162, 104, 64, 32, 107, 144, 235, 133, 255, 128],
                   cursor: 98
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 104,
                   array: [175, 29, 246, 162, 104, 64, 16, 107, 144, 235, 133, 143, 128],
                   cursor: 98
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 440,
                   array: _,
                   cursor: 440
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 448,
                   array: _,
                   cursor: 448
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{
                   length: 432,
                   array: _,
                   cursor: 432
                 },
                 kind: :ordinary
               },
               %Ton.Cell{
                 refs: [],
                 data: %Ton.Bitstring{length: 40, array: [244, 0, 201, 237, 84], cursor: 40},
                 kind: :ordinary
               }
             ] = Enum.reverse(reversed_cells)
    end
  end

  describe "hash/1" do
    test "calculates cell hash" do
      {:ok, contract_source_code} =
        Base.decode16(
          "B5EE9C724101010100530000A2FF0020DD2082014C97BA9730ED44D0D70B1FE0A4F260810200D71820D70B1FED44D0D31FD3FFD15112BAF2A122F901541044F910F2A2F80001D31F3120D74A96D307D402FB00DED1A4C8CB1FCBFFC9ED54D0E2786F",
          case: :upper
        )

      [cell] = Boc.parse(contract_source_code)

      assert "d4902fcc9fad74698fa8e353220a68da0dcf72e32bcb2eb9ee04217c17d3062c" == Cell.hash(cell)
    end
  end
end
