defmodule Ton.Boc.HeaderTest do
  use ExUnit.Case

  alias Ton.Boc.Header

  describe "parse_header/1" do
    test "parses a header" do
      {:ok, source} =
        Base.decode64(
          "te6ccgECFAEAAtQAART/APSkE/S88sgLAQIBIAIDAgFIBAUE+PKDCNcYINMf0x/THwL4I7vyZO1E0NMf0x/T//QE0VFDuvKhUVG68qIF+QFUEGT5EPKj+AAkpMjLH1JAyx9SMMv/UhD0AMntVPgPAdMHIcAAn2xRkyDXSpbTB9QC+wDoMOAhwAHjACHAAuMAAcADkTDjDQOkyMsfEssfy/8QERITAubQAdDTAyFxsJJfBOAi10nBIJJfBOAC0x8hghBwbHVnvSKCEGRzdHK9sJJfBeAD+kAwIPpEAcjKB8v/ydDtRNCBAUDXIfQEMFyBAQj0Cm+hMbOSXwfgBdM/yCWCEHBsdWe6kjgw4w0DghBkc3RyupJfBuMNBgcCASAICQB4AfoA9AQw+CdvIjBQCqEhvvLgUIIQcGx1Z4MesXCAGFAEywUmzxZY+gIZ9ADLaRfLH1Jgyz8gyYBA+wAGAIpQBIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UAXKwjiOCEGRzdHKDHrFwgBhQBcsFUAPPFiP6AhPLassfyz/JgED7AJJfA+ICASAKCwBZvSQrb2omhAgKBrkPoCGEcNQICEekk30pkQzmkD6f+YN4EoAbeBAUiYcVnzGEAgFYDA0AEbjJftRNDXCx+AA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYAIBIA4PABmtznaiaEAga5Drhf/AABmvHfaiaEAQa5DrhY/AAG7SB/oA1NQi+QAFyMoHFcv/ydB3dIAYyMsFywIizxZQBfoCFMtrEszMyXP7AMhAFIEBCPRR8qcCAHCBAQjXGPoA0z/IVCBHgQEI9FHyp4IQbm90ZXB0gBjIywXLAlAGzxZQBPoCFMtqEssfyz/Jc/sAAgBsgQEI1xj6ANM/MFIkgQEI9Fnyp4IQZHN0cnB0gBjIywXLAlAFzxZQA/oCE8tqyx8Syz/Jc/sAAAr0AMntVA=="
        )

      assert %Ton.Boc.Header{
               has_idx: false,
               hash_crc32: false,
               has_cache_bits: false,
               flags: 0,
               size_bytes: 1,
               off_bytes: 2,
               cells_num: 20,
               roots_num: 1,
               absent_num: 0,
               tot_cells_size: 724,
               root_list: [0],
               index: [],
               cells_data:
                 <<1, 20, 255, 0, 244, 164, 19, 244, 188, 242, 200, 11, 1, 2, 1, 32, 2, 3, 2, 1,
                   72, 4, 5, 4, 248, 242, 131, 8, 215, 24, 32, 211, 31, 211, 31, 211, 31, 2, 248,
                   35, 187, 242, 100, 237, 68, 208, 211, 31, 211, 31, 211, 255, 244, 4, 209, 81,
                   67, 186, 242, 161, 81, 81, 186, 242, 162, 5, 249, 1, 84, 16, 100, 249, 16, 242,
                   163, 248, 0, 36, 164, 200, 203, 31, 82, 64, 203, 31, 82, 48, 203, 255, 82, 16,
                   244, 0, 201, 237, 84, 248, 15, 1, 211, 7, 33, 192, 0, 159, 108, 81, 147, 32,
                   215, 74, 150, 211, 7, 212, 2, 251, 0, 232, 48, 224, 33, 192, 1, 227, 0, 33,
                   192, 2, 227, 0, 1, 192, 3, 145, 48, 227, 13, 3, 164, 200, 203, 31, 18, 203, 31,
                   203, 255, 16, 17, 18, 19, 2, 230, 208, 1, 208, 211, 3, 33, 113, 176, 146, 95,
                   4, 224, 34, 215, 73, 193, 32, 146, 95, 4, 224, 2, 211, 31, 33, 130, 16, 112,
                   108, 117, 103, 189, 34, 130, 16, 100, 115, 116, 114, 189, 176, 146, 95, 5, 224,
                   3, 250, 64, 48, 32, 250, 68, 1, 200, 202, 7, 203, 255, 201, 208, 237, 68, 208,
                   129, 1, 64, 215, 33, 244, 4, 48, 92, 129, 1, 8, 244, 10, 111, 161, 49, 179,
                   146, 95, 7, 224, 5, 211, 63, 200, 37, 130, 16, 112, 108, 117, 103, 186, 146,
                   56, 48, 227, 13, 3, 130, 16, 100, 115, 116, 114, 186, 146, 95, 6, 227, 13, 6,
                   7, 2, 1, 32, 8, 9, 0, 120, 1, 250, 0, 244, 4, 48, 248, 39, 111, 34, 48, 80, 10,
                   161, 33, 190, 242, 224, 80, 130, 16, 112, 108, 117, 103, 131, 30, 177, 112,
                   128, 24, 80, 4, 203, 5, 38, 207, 22, 88, 250, 2, 25, 244, 0, 203, 105, 23, 203,
                   31, 82, 96, 203, 63, 32, 201, 128, 64, 251, 0, 6, 0, 138, 80, 4, 129, 1, 8,
                   244, 89, 48, 237, 68, 208, 129, 1, 64, 215, 32, 200, 1, 207, 22, 244, 0, 201,
                   237, 84, 1, 114, 176, 142, 35, 130, 16, 100, 115, 116, 114, 131, 30, 177, 112,
                   128, 24, 80, 5, 203, 5, 80, 3, 207, 22, 35, 250, 2, 19, 203, 106, 203, 31, 203,
                   63, 201, 128, 64, 251, 0, 146, 95, 3, 226, 2, 1, 32, 10, 11, 0, 89, 189, 36,
                   43, 111, 106, 38, 132, 8, 10, 6, 185, 15, 160, 33, 132, 112, 212, 8, 8, 71,
                   164, 147, 125, 41, 145, 12, 230, 144, 62, 159, 249, 131, 120, 18, 128, 27, 120,
                   16, 20, 137, 135, 21, 159, 49, 132, 2, 1, 88, 12, 13, 0, 17, 184, 201, 126,
                   212, 77, 13, 112, 177, 248, 0, 61, 178, 157, 251, 81, 52, 32, 64, 80, 53, 200,
                   125, 1, 12, 0, 178, 50, 129, 242, 255, 242, 116, 0, 96, 64, 66, 61, 2, 155,
                   232, 76, 96, 2, 1, 32, 14, 15, 0, 25, 173, 206, 118, 162, 104, 64, 32, 107,
                   144, 235, 133, 255, 192, 0, 25, 175, 29, 246, 162, 104, 64, 16, 107, 144, 235,
                   133, 143, 192, 0, 110, 210, 7, 250, 0, 212, 212, 34, 249, 0, 5, 200, 202, 7,
                   21, 203, 255, 201, 208, 119, 116, 128, 24, 200, 203, 5, 203, 2, 34, 207, 22,
                   80, 5, 250, 2, 20, 203, 107, 18, 204, 204, 201, 115, 251, 0, 200, 64, 20, 129,
                   1, 8, 244, 81, 242, 167, 2, 0, 112, 129, 1, 8, 215, 24, 250, 0, 211, 63, 200,
                   84, 32, 71, 129, 1, 8, 244, 81, 242, 167, 130, 16, 110, 111, 116, 101, 112,
                   116, 128, 24, 200, 203, 5, 203, 2, 80, 6, 207, 22, 80, 4, 250, 2, 20, 203, 106,
                   18, 203, 31, 203, 63, 201, 115, 251, 0, 2, 0, 108, 129, 1, 8, 215, 24, 250, 0,
                   211, 63, 48, 82, 36, 129, 1, 8, 244, 89, 242, 167, 130, 16, 100, 115, 116, 114,
                   112, 116, 128, 24, 200, 203, 5, 203, 2, 80, 5, 207, 22, 80, 3, 250, 2, 19, 203,
                   106, 203, 31, 18, 203, 63, 201, 115, 251, 0, 0, 10, 244, 0, 201, 237, 84>>
             } == Header.parse(source)
    end
  end
end
