defmodule Ton.CellTest do
  use ExUnit.Case

  alias Ton.Bitstring
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
                 data: %Ton.Bitstring{
                   array: [255, 0, 244, 164, 19, 244, 188, 242, 200, 11],
                   cursor: 80,
                   length: 80
                 },
                 kind: :ordinary,
                 refs: [1]
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: [0], cursor: 2, length: 8},
                 kind: :ordinary,
                 refs: [2, 3]
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: '@', cursor: 4, length: 8},
                 kind: :ordinary,
                 refs: [4, 5]
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 992,
                   length: 992
                 },
                 kind: :ordinary,
                 refs: [16, 17, 18, 19]
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 920,
                   length: 920
                 },
                 kind: :ordinary,
                 refs: [6, 7]
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: [0], cursor: 2, length: 8},
                 kind: :ordinary,
                 refs: '\b\t'
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 480,
                   length: 480
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 552,
                   length: 552
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: [0], cursor: 2, length: 8},
                 kind: :ordinary,
                 refs: '\n\v'
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 357,
                   length: 360
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: 'P', cursor: 4, length: 8},
                 kind: :ordinary,
                 refs: '\f\r'
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: [184, 201, 126, 212, 77, 13, 112, 177, 240],
                   cursor: 68,
                   length: 72
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 242,
                   length: 248
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: [0], cursor: 2, length: 8},
                 kind: :ordinary,
                 refs: [14, 15]
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: [173, 206, 118, 162, 104, 64, 32, 107, 144, 235, 133, 255, 128],
                   cursor: 97,
                   length: 104
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: [175, 29, 246, 162, 104, 64, 16, 107, 144, 235, 133, 143, 128],
                   cursor: 97,
                   length: 104
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 440,
                   length: 440
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 448,
                   length: 448
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{
                   array: _,
                   cursor: 432,
                   length: 432
                 },
                 kind: :ordinary,
                 refs: []
               },
               %Ton.Cell{
                 data: %Ton.Bitstring{array: [244, 0, 201, 237, 84], cursor: 40, length: 40},
                 kind: :ordinary,
                 refs: []
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

      assert "d4902fcc9fad74698fa8e353220a68da0dcf72e32bcb2eb9ee04217c17d3062c" ==
               Cell.hash(cell) |> Base.encode16(case: :lower)
    end

    test "calculates cell hash for cell with refs" do
      nested_cell = %Cell{
        data: %Bitstring{
          array:
            hex_to_list(
              "d001d0d3032171b0925f04e022d749c120925f04e002d31f218210706c7567bd22821064737472bdb0925f05e003fa403020fa4401c8ca07cbffc9d0ed44d0810140d721f404305c810108f40a6fa131b3925f07e005d33fc8258210706c7567ba923830e30d03821064737472ba925f06e30d"
            ),
          cursor: 920,
          length: 920
        },
        kind: :ordinary,
        refs: [
          %Cell{
            data: %Bitstring{
              array:
                hex_to_list(
                  "01fa00f40430f8276f2230500aa121bef2e0508210706c7567831eb17080185004cb0526cf1658fa0219f400cb6917cb1f5260cb3f20c98040fb0006"
                ),
              cursor: 480,
              length: 480
            },
            kind: :ordinary,
            refs: []
          },
          %Cell{
            data: %Bitstring{
              array:
                hex_to_list(
                  "5004810108f45930ed44d0810140d720c801cf16f400c9ed540172b08e23821064737472831eb17080185005cb055003cf1623fa0213cb6acb1fcb3fc98040fb00925f03e2"
                ),
              cursor: 552,
              length: 552
            },
            kind: :ordinary,
            refs: []
          }
        ]
      }

      assert "aceb86285d6598f29c2ed99f2ce24228cb752a0ac3a58ae4d5191c5fcb989c91" ==
               Cell.hash(nested_cell) |> Base.encode16(case: :lower)
    end

    test "calculates cell hash for cell with 2 level refs" do
      cell = %Cell{
        refs: [
          %Cell{
            refs: [],
            data: %Bitstring{
              length: 248,
              array: [
                178,
                157,
                251,
                81,
                52,
                32,
                64,
                80,
                53,
                200,
                125,
                1,
                12,
                0,
                178,
                50,
                129,
                242,
                255,
                242,
                116,
                0,
                96,
                64,
                66,
                61,
                2,
                155,
                232,
                76,
                64
              ],
              cursor: 242
            },
            kind: :ordinary
          },
          %Cell{
            refs: [
              %Cell{
                refs: [],
                data: %Bitstring{
                  length: 104,
                  array: [173, 206, 118, 162, 104, 64, 32, 107, 144, 235, 133, 255, 128],
                  cursor: 97
                },
                kind: :ordinary
              },
              %Cell{
                refs: [],
                data: %Bitstring{
                  length: 104,
                  array: [175, 29, 246, 162, 104, 64, 16, 107, 144, 235, 133, 143, 128],
                  cursor: 97
                },
                kind: :ordinary
              }
            ],
            data: %Bitstring{length: 8, array: [0], cursor: 2},
            kind: :ordinary
          }
        ],
        data: %Bitstring{length: 8, array: [80], cursor: 4},
        kind: :ordinary
      }

      assert "050ff76bdca185d0dce2781ff13bfe352a3efc1a8e1276a6ac5bc38ba4b3d67e" ==
               Cell.hash(cell) |> Base.encode16(case: :lower)
    end
  end

  describe "serialize/2" do
    test "serializes a cell" do
      cell =
        Base.decode64!(
          "te6ccgECFAEAAtQAART/APSkE/S88sgLAQIBIAIDAgFIBAUE+PKDCNcYINMf0x/THwL4I7vyZO1E0NMf0x/T//QE0VFDuvKhUVG68qIF+QFUEGT5EPKj+AAkpMjLH1JAyx9SMMv/UhD0AMntVPgPAdMHIcAAn2xRkyDXSpbTB9QC+wDoMOAhwAHjACHAAuMAAcADkTDjDQOkyMsfEssfy/8QERITAubQAdDTAyFxsJJfBOAi10nBIJJfBOAC0x8hghBwbHVnvSKCEGRzdHK9sJJfBeAD+kAwIPpEAcjKB8v/ydDtRNCBAUDXIfQEMFyBAQj0Cm+hMbOSXwfgBdM/yCWCEHBsdWe6kjgw4w0DghBkc3RyupJfBuMNBgcCASAICQB4AfoA9AQw+CdvIjBQCqEhvvLgUIIQcGx1Z4MesXCAGFAEywUmzxZY+gIZ9ADLaRfLH1Jgyz8gyYBA+wAGAIpQBIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UAXKwjiOCEGRzdHKDHrFwgBhQBcsFUAPPFiP6AhPLassfyz/JgED7AJJfA+ICASAKCwBZvSQrb2omhAgKBrkPoCGEcNQICEekk30pkQzmkD6f+YN4EoAbeBAUiYcVnzGEAgFYDA0AEbjJftRNDXCx+AA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYAIBIA4PABmtznaiaEAga5Drhf/AABmvHfaiaEAQa5DrhY/AAG7SB/oA1NQi+QAFyMoHFcv/ydB3dIAYyMsFywIizxZQBfoCFMtrEszMyXP7AMhAFIEBCPRR8qcCAHCBAQjXGPoA0z/IVCBHgQEI9FHyp4IQbm90ZXB0gBjIywXLAlAGzxZQBPoCFMtqEssfyz/Jc/sAAgBsgQEI1xj6ANM/MFIkgQEI9Fnyp4IQZHN0cnB0gBjIywXLAlAFzxZQA/oCE8tqyx8Syz/Jc/sAAAr0AMntVA=="
        )
        |> Boc.parse()
        |> Enum.at(0)

      assert "b5ee9c72c10214010002d400000d00120094009b00d3010d0146014b0150017f0184018f0194019901a801b701d8024f029602d40114ff00f4a413f4bcf2c80b01020120070204f8f28308d71820d31fd31fd31f02f823bbf264ed44d0d31fd31fd3fff404d15143baf2a15151baf2a205f901541064f910f2a3f80024a4c8cb1f5240cb1f5230cbff5210f400c9ed54f80f01d30721c0009f6c519320d74a96d307d402fb00e830e021c001e30021c002e30001c0039130e30d03a4c8cb1f12cb1fcbff06050403000af400c9ed54006c810108d718fa00d33f305224810108f459f2a782106473747270748018c8cb05cb025005cf165003fa0213cb6acb1f12cb3fc973fb000070810108d718fa00d33fc8542047810108f451f2a782106e6f746570748018c8cb05cb025006cf165004fa0214cb6a12cb1fcb3fc973fb0002006ed207fa00d4d422f90005c8ca0715cbffc9d077748018c8cb05cb0222cf165005fa0214cb6b12ccccc973fb00c84014810108f451f2a70202014811080201200a090059bd242b6f6a2684080a06b90fa0218470d4080847a4937d29910ce6903e9ff9837812801b7810148987159f31840201200c0b0011b8c97ed44d0d70b1f8020158100d0201200f0e0019af1df6a26840106b90eb858fc00019adce76a26840206b90eb85ffc0003db29dfb513420405035c87d010c00b23281f2fff274006040423d029be84c6002e6d001d0d3032171b0925f04e022d749c120925f04e002d31f218210706c7567bd22821064737472bdb0925f05e003fa403020fa4401c8ca07cbffc9d0ed44d0810140d721f404305c810108f40a6fa131b3925f07e005d33fc8258210706c7567ba923830e30d03821064737472ba925f06e30d1312008a5004810108f45930ed44d0810140d720c801cf16f400c9ed540172b08e23821064737472831eb17080185005cb055003cf1623fa0213cb6acb1fcb3fc98040fb00925f03e2007801fa00f40430f8276f2230500aa121bef2e0508210706c7567831eb17080185004cb0526cf1658fa0219f400cb6917cb1f5260cb3f20c98040fb0006e06c70a3" ==
               Cell.serialize(cell) |> Base.encode16(case: :lower)
    end
  end

  defp hex_to_list(hex_string) do
    hex_string
    |> Base.decode16!(case: :lower)
    |> :binary.bin_to_list()
  end
end
